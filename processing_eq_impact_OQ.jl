# """

# Assessing the impact from earthquake by sampling the fragilties from the METEOR dataset.

# """

# Loading libraries and paths
using Pkg
cd("/Users/alexdunant/Documents/Github/Bhjopur_5p1")
# cd("C:\\Users\\nszf25\\Documents\\Github\\Bhjopur_5p1")
Pkg.activate("./JL_Bhjopur_5p1")


begin
    using JSON
    using DataFrames
    using CSV
    using Shapefile
    using Distributions
    using GMT
    using ProgressBars
    using Statistics
#     using PyCall
end


# path
server = "Y://_TEMP//Server_Gitdata"
# server = "/Volumes/Nepal/SajagNepal/003_GIS_data/_TEMP/Server_Gitdata"
directory = joinpath(server, "Bhojpur_Mw5.1")


# data
gmf = CSV.read(joinpath(directory, "OQoutputs", "output-7-gmf_data-csv",  "gmf-data_12.csv"), header=3, DataFrame)
sitemesh = CSV.read(joinpath(directory, "OQoutputs", "output-7-gmf_data-csv",  "sitemesh_12.csv"), DataFrame)

# merge OQ output together
OQ = leftjoin(sitemesh, gmf, on= :site_id)
OQ = coalesce.(OQ, 0.0)

# merge OQ outputs with the building dataset to do analysis
b = DataFrame(Shapefile.Table(joinpath(directory, "shapefile", "bldgs_preprocs_E4.shp")))
b = leftjoin(b, OQ, on = :su_id => :site_id)

################################## EARTHQUAKE IMPACT #############################

# use JSON to read building types
typo = @. JSON.parse(b.constructi)


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


for (d, pga) in ProgressBar(zip(typo, b.gmv_PGA))

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
r = convert(Array{Float64}, reduce(hcat, list_FRAGILITY))

# add results to impact dataframe
b[!, :low_case] = r[1,:]
b[!, :mid_case] = r[2,:]
b[!, :high_case] = r[3,:]

# get number of impact per districts
r_count = combine(groupby(r, :DISTRICT), [:low_case, :mid_case, :high_case] .=> sum)

# Plot
bar(1:length(r_count.DISTRICT), Matrix(r_count[!, [:high_case_sum, :mid_case_sum, :low_case_sum]]), width=0.9,
        fill=["lightred", "lightgreen", "lightblue"],
        yticks=Tuple([x for x in r_count.DISTRICT]),
        hbar=true)
