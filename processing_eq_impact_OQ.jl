# """

# Assessing the impact from earthquake by sampling the fragilties from the METEOR dataset.

# """

# Loading libraries and paths
using Pkg
cd("/Users/alexdunant/Documents/Github/SN_MH-methodology")
Pkg.activate("./SN_MH_methodology")


begin
    using JSON
    using DataFrames
    using CSV
    using Shapefile
    using Distributions
    using GMT
    using ProgressBars
    using Statistics
    using PyCall
end


# path
# server = "Y://_TEMP//Server_Gitdata"
server = "/Volumes/Nepal/SajagNepal/003_GIS_data/_TEMP/Server_Gitdata"
directory = joinpath(server, "SN_MH-methodology")


# data
@time impact = CSV.read(joinpath(directory, "LS_impact_on_Buildings_NOCONN_It5000_2022-08-17.csv"), DataFrame)
@time bldg = DataFrame(Shapefile.Table(joinpath(directory, "bldgs_preprocs_light_districts.shp")))
# @time bldg = gmtread(joinpath(directory, "bldgs_preprocs_light_districts.shp"))





################################## EARTHQUAKE IMPACT #############################



# use JSON to read building types
typo = @. JSON.parse(impact.constructi)

# fragilities paramters per typologies1.90, 0.93

# Hazus(http://drm.cenn.org/Trainings/Multi%20Hazard%20Risk%20Assessment/Lectures_ENG/Session%2006%20Risk%20Analysis/Background/HAZUS%20EQ_TM_Chapter05%20building%20losses.pdf)
C99ref = ["Didier et al., 2017", "Gautam et al., 2018", "Hazus C3M low code"]
C99mean = [1.95, 1.29, 0.51]
C99scale = [0.71, 0.83, 0.64]

# MURref = ["Guragain et al., 2015", "Gautam et al., 2018", "Didier et al., 2017"]
# MURmean = [0.23, 0.22, 1.26]
# MURscale = [0.31, 0.48, 1.96]

MURref = ["Didier et al., 2017 - Brick Cement", "Guragain et al., 2015", "Didier et al., 2017 - Brick Mud"]
MURmean = [1.9, 0.23, 1.26]
MURscale = [0.93, 0.31, 1.96]

MUR_STRUBref = ["Gautam et al., 2018", "Guragain et al., 2015", "Didier et al., 2017"]
MUR_STRUBmean = [0.39, 0.203, 1.26]
MUR_STRUBscale = [0.69, 0.308, 1.96]

Sref = ["Hazus S3 moderate code", "Hazus S3 low code", "Hazus S3 low code"]
Smean = [0.60, 0.38, 0.38]
Sscale = [0.64, 0.64, 0.64]

Wref = ["Hazus W1 moderate code", "Hazus W1 low code", "Hazus W1 low code"]
Wmean = [1.34, 0.95, 0.95]
Wscale = [0.64, 0.64, 0.64]


# iterate METEOR dictionay at each building to get fragility for pga values
list_FRAGILITY = []
# get the true mean
μ_for_mean(m, μ) = log(m) - μ^2/2

for (d, pga) in ProgressBar(zip(typo, impact.pga))

    tmp = []

    # iterate low, mid, high cases
    for i in eachindex(C99mean)

        FRAGILITY = [ startswith(t, "C99") ? cdf(LogNormal(μ_for_mean(C99mean[i], C99scale[i])), pga) :
        startswith(t, "MUR+CL99") ? cdf(LogNormal(μ_for_mean(MURmean[i], MURscale[i])), pga) :
        occursin("STRUB", t) ? cdf(LogNormal(μ_for_mean(MUR_STRUBmean[i], MUR_STRUBscale[i])), pga) :
        startswith(t, "S") ? cdf(LogNormal(μ_for_mean(Smean[i], Sscale[i])), pga) :
        startswith(t, "W") ? cdf(LogNormal(μ_for_mean(Wmean[i], Wscale[i])), pga) :
        cdf(LogNormal(μ_for_mean(MUR_STRUBmean[1], MUR_STRUBscale[i])), pga)
        for (t,c) in d]

        frag_count = [c for (t,c) in d]

        # @show(i)
        # @show(pga)
        # @show(d)
        # @show(FRAGILITY, frag_count)

        # repeat to calucate True mean fargility value
        frag_weight = reduce(vcat, fill(FRAGILITY[i], frag_count[i]) for i in 1:length(FRAGILITY))
        m_frag = mean(frag_weight)
        # @show freg_weight
        # @show(m_frag)

        push!(tmp, m_frag)

        # @show tmp
        # println(" ")

    end

    push!(list_FRAGILITY, tmp)

end




####### process results #################


# add result to impact (need to turn array of array in Matrix)
@time r = convert(Array{Float64}, reduce(hcat, list_FRAGILITY))

# Create dataFrame based on the gmtread
# dfb = DataFrame(osm_id = map(x->x.attrib["osm_id"],bldg),district=map(x -> x.attrib["districts"],bldg),ORDER=1:length(bldg))

# add results to impact dataframe
impact[!, :low_case] = r[1,:]
impact[!, :mid_case] = r[2,:]
impact[!, :high_case] = r[3,:]
r = innerjoin(impact, bldg, on= :osm_id, makeunique=true)

# get number of impact per districts
r_count = combine(groupby(r, :DISTRICT), [:low_case, :mid_case, :high_case] .=> sum)
# Keep only existing districts
r_count = r_count[completecases(r_count), :]

# merge with Chaulagain et al
chaulagain = CSV.read(joinpath(directory, "Bldg_collapse_Chaulagain_2018.csv"), DataFrame)
transform!(chaulagain, Not(r"DISTRICT") => (+) => :total_damage)
r_count = leftjoin(r_count, chaulagain[!, [:DISTRICT, :total_damage]], on="DISTRICT")

# Get only the column present in Chaulagain
r_count = r_count[completecases(r_count), :]
r_count.actual_damage = convert(Array{Float64}, r_count.total_damage)

# calculate coefficient of correlation
coef = cor(r_count.mid_case_sum, r_count.actual_damage)
println("coefficient correlation score of $(round(coef, digits=4))")


# Plot
begin
    bar(1:length(r_count.DISTRICT), Matrix(r_count[!, [:high_case_sum, :actual_damage]]), width=0.9,
        fill=["lightred", "p11"],
        yticks=Tuple([x for x in r_count.DISTRICT]),
        hbar=true)

    bar!(1:length(r_count.DISTRICT), Matrix(r_count[!, [:mid_case_sum, :actual_damage]]), width=0.9,
        fill=["lightgreen", "p11"],
        yticks=Tuple([x for x in r_count.DISTRICT]),
        hbar=true)

    bar!(1:length(r_count.DISTRICT), Matrix(r_count[!, [:low_case_sum, :actual_damage]]), width=0.9,
        fill=["lightblue", "p11"],
        yticks=Tuple([x for x in r_count.DISTRICT]),
        frame=(title="Severe impact to buildings", axes=:WSrt), hbar=true,
        savefig=joinpath(pwd(), "bar_building_damage.png"),
        show=true)
end
