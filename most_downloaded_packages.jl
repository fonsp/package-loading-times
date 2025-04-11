### A Pluto.jl notebook ###
# v0.19.29

using Markdown
using InteractiveUtils

# ╔═╡ b8592dff-07d0-4ae4-b69e-64cc74bd17cc
import Pkg

# ╔═╡ 352bb1f4-50f9-4450-a6f5-ca342eaaafe2
using Downloads: download

# ╔═╡ 1b20b0b3-c9fb-403f-87fa-9d85e8572a0d
using GZip

# ╔═╡ fe53e49c-d4a9-4329-a1e2-c3f83de2a9c3
using CSV

# ╔═╡ 882badc4-dd60-418d-82de-e8f4a4f4e401
using DataFrames

# ╔═╡ 337aa6ea-e090-4f12-88f5-ea16a2b3d009
using DelimitedFiles

# ╔═╡ 34641f5f-bce1-4a04-af87-54e2ef7b515b
using Tables

# ╔═╡ 6729abd8-3df3-4c6a-8ee6-2117751dbabe
using RegistryInstances

# ╔═╡ 85d985fa-4c03-40e9-99d6-6b0517d02d8a
using UUIDs

# ╔═╡ 8d70b100-2df2-11ed-20da-8d38fabd643a
url = "https://julialang-logs.s3.amazonaws.com/public_outputs/current/package_requests.csv.gz"

# ╔═╡ 66b19454-86e2-44ad-8367-c661acaaddd3
filename_gz = download(url)

# ╔═╡ 247afed8-478d-487d-a643-15ce64db4cbc
filename = let
	t = tempname() * ".csv"
	write(t, GZip.open(read, filename_gz))
	t
end

# ╔═╡ 116a60a0-347a-413b-977c-fd3a58e6e495
data_raw = DataFrame(CSV.File(filename));

# ╔═╡ 2f45374c-63af-4e20-99f0-71ddea504a13
data_200 = filter(e -> e.status == 200 && coalesce(e.client_type,"") == "user", data_raw)

# ╔═╡ aa31dde3-fb6b-4518-ab58-3ad90444ec05
general_registry = only(
	filter!(
		x -> x.name == "General",
		RegistryInstances.reachable_registries(),
	)
)

# ╔═╡ 0a2d6489-a563-4f47-84b1-98f3b9f29bd2
general_registry.pkgs

# ╔═╡ 4a8c6a62-ba76-4565-9062-6c79b9800f24
registered_names = DataFrame(((; package_uuid=string(p.uuid), name=p.name) for p in values(general_registry.pkgs)))

# ╔═╡ 5a05a5bb-69bc-44db-b41a-12e76144c969
data_200_names = innerjoin(data_200, registered_names, on=:package_uuid)

# ╔═╡ b559c02f-a356-4d34-aba8-f5752414b6a9
popular = sort(data_200_names, :request_count; rev=true)#[!, [:package_uuid, :request_count]]

# ╔═╡ a66932de-d79e-4544-ab4f-fbfe3a10eb9e


# ╔═╡ 139d3f82-2fb5-4d50-b426-c6c0136ab5d5
popular

# ╔═╡ fb69f248-9b78-44f5-9cd7-8d49dc2c17c3
pp = general_registry.pkgs[UUID("91a5bcdd-55d7-5caf-9e0b-520d859cae80")]

# ╔═╡ 2a3a7470-6520-43b9-9877-95c18379cae0
filter(startswith(pp.path), general_registry.in_memory_registry |> keys)

# ╔═╡ d5b284e8-48e4-45ff-b60e-897441ec1a79
perw = registry_info(pp).deps

# ╔═╡ 6df36e65-b8e7-4aca-a916-2844e700f33e


# ╔═╡ f0b251d4-c538-472b-9ce3-e2b1ea8d3481
struct StdlibEntry
	name::String
	uuid::UUID
	version::Union{Nothing,VersionNumber}
end

# ╔═╡ e1818210-c67c-420b-a4e1-64df56c64fc2
const stdlib_entries = [
	if v isa String
		StdlibEntry(v, k, nothing) 
	else
		StdlibEntry(v[1], k, v[2]) 
	end
	for (k,v) in Pkg.Types.stdlibs()
]

# ╔═╡ 3a04e925-7c34-4ef1-acbe-dea9199033d9
const stdlib_registry = Dict(e.uuid => e for e in stdlib_entries)

# ╔═╡ 76f026c3-3610-4fab-81b6-8380f35fb1c2
const Entry = Union{PkgEntry, StdlibEntry}

# ╔═╡ 5fcb704e-5878-4674-bc75-f4d4a70aed63
vs = collect(keys(perw))

# ╔═╡ d32adabf-5bdf-4622-ac42-f31bff1d007b
top_uuids = popular[ 1:1000, :package_uuid]

# ╔═╡ 1a18c3e7-aaf3-4a21-9a06-a94e37650f9a
top_entries = vcat(
	stdlib_entries,
	[general_registry.pkgs[UUID(u)] for u in top_uuids],
)

# ╔═╡ 14077034-878e-4bcd-9468-fb6f9141aaad
# dependencies(stdlib_entries[15]) |> collect

# ╔═╡ 05cf4427-ff70-473b-ab32-74ef28f26404
# TOML.parsefile(joinpath(Pkg.Types.stdlib_path("LinearAlgebra"), "Project.toml"))

# ╔═╡ cae907f9-2976-4899-9070-8c433e541ef4
general_registry

# ╔═╡ b27c0478-6669-402d-ab60-dfb8edde788c
RegistryInstances.registry_info(top_entries[800]).deps

# ╔═╡ 43223cc7-3af8-4780-a5cc-289b31851fee
getindex

# ╔═╡ fee23f41-5427-440f-8e3c-9a4509873219
latest_version(entry::PkgEntry) = RegistryInstances.registry_info(entry).version_info |> keys |> maximum

# ╔═╡ e447c427-e63b-464f-bbb4-4d2104f2a32e
function dependencies(entry::PkgEntry)
	deps = RegistryInstances.registry_info(entry).deps

	v = latest_version(entry)

	uuids = union!(
		Set{UUID}(), 
		(
			values(val)
			for (range, val) in deps 
			if v ∈ range
		)...
	)

	Iterators.filter(!isnothing, (
		get(general_registry.pkgs, u, get(stdlib_registry, u, nothing))
		for u in uuids
	))
end

# ╔═╡ f0fa3338-bd47-4841-8f9b-4723ed00b30c
pp

# ╔═╡ f2fb2e4f-5862-49d4-9fc1-a15f76e2da48
latest_version(pp)

# ╔═╡ b5ba884e-fd95-4131-b1ee-dfcefcbdf3af
deps = perw

# ╔═╡ 876da4cd-23e4-4caa-ae8f-e32d994f8f20
uuids = union!(
	Set{UUID}(), 
	(
		values(val)
		for (range, val) in deps 
		if latest_version(pp) ∈ range
	)...
)

# ╔═╡ 8bef7abd-963c-4edf-aca2-bbcbf22099cf
[
	get(general_registry.pkgs, u, nothing)
	for u in uuids
]

# ╔═╡ 75f9cb1d-85c5-4c2b-82e4-bcba298ca950
import TOML

# ╔═╡ 57312b16-9296-40cb-ac9a-861f38433d44
function dependencies(entry::StdlibEntry)
	project = TOML.parsefile(joinpath(Pkg.Types.stdlib_path(entry.name), "Project.toml"))

	deps = get(project, "deps", Dict{String,Any}())

	uuids = UUID.(values(deps))

	Iterators.filter(!isnothing, (
		get(stdlib_registry, u, nothing)
		for u in uuids
	))
	# Entry[]
end

# ╔═╡ e4570d9a-5fe4-4214-8da1-f6d4d0d79b83
dsd = dependencies(pp) |> collect

# ╔═╡ afb17c6b-fd9b-4b29-aea2-28bee8f4d2ea
function sort_by_deps(entry::Entry)
	deps = dependencies(entry)

	union!(Entry[], (
		sort_by_deps(d) for d in deps
		)...,
		[entry]
	)
end

# ╔═╡ 79fd7a4c-2637-4a73-9539-73d624f5a0d0
function sort_by_deps2!(found::Vector{Entry}, entry::Entry)
	if entry ∉ found
		deps = dependencies(entry)
	
		for d in deps
			if d !== entry
				sort_by_deps2!(found, d)
			end
		end

		push!(found, entry)
	end
	found
end

# ╔═╡ 4252936f-5435-4d62-a5a2-c5dacc936c6f
sorted_top = let
	result = Entry[]
	for entry in top_entries
		sort_by_deps2!(result, entry)
	end
	result
end

# ╔═╡ bacc149e-46c1-4fa9-8daa-86e119bf8399
sorted_top_names = [p.name for p in sorted_top]

# ╔═╡ e1bff052-a0a2-41a4-ac75-495e6d2d62a9
write("top_packages_sorted.txt", join(sorted_top_names, "\n"))

# ╔═╡ 50aeef93-d2b6-464e-8aed-2fab5a6d172f
Text(join(sorted_top_names, "\n"))

# ╔═╡ b31351ba-59e9-46e2-be48-09204c56c20d
all(eachindex(sorted_top)) do i
	dependencies(sorted_top[i]) ⊆ sorted_top[1:i-1]
end

# ╔═╡ 1aebde1a-1221-43f4-8c3b-e7ae54c3528e
sorted_names_with_deps = [
	join((e.name for e in (p, dependencies(p)...)), ",")
	for p in sorted_top
]

# ╔═╡ da6c519b-f35b-48d2-a897-dbbe58a69711
Text(join(sorted_names_with_deps, "\n"))

# ╔═╡ 2161f2d2-858d-4edf-ae33-eca9d9ef4980
write("top_packages_sorted_with_deps.txt", join(sorted_names_with_deps, "\n"))

# ╔═╡ 1fa4d8c9-d631-4cbb-a1f8-9789b465af0d
general_registry.in_memory_registry[top_entries[800].path *"/Deps.toml"] |> TOML.parse


# ╔═╡ 94c2ae47-7350-42e8-abb9-7be7e624110a
methodswith(PkgEntry)

# ╔═╡ 9836a44e-2eab-4e4d-be75-2e7d801198c7
filter(r -> r.name ∈ ("Plots","Pluto"), popular)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
DelimitedFiles = "8bb1440f-4735-579b-a4ab-409b98df4dab"
Downloads = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
GZip = "92fee26a-97fe-5a0c-ad85-20a5f3185b63"
Pkg = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
RegistryInstances = "2792f1a3-b283-48e8-9a74-f99dce5104f3"
TOML = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
Tables = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
UUIDs = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[compat]
CSV = "~0.10.11"
DataFrames = "~1.6.1"
GZip = "~0.5.2"
RegistryInstances = "~0.1.0"
Tables = "~1.11.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.3"
manifest_format = "2.0"
project_hash = "da4e8f33c5e0ea26c435dab773bef6b555dcfb60"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "PrecompileTools", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings", "WorkerUtilities"]
git-tree-sha1 = "44dbf560808d49041989b8a96cae4cffbeb7966a"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.11"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "cd67fc487743b2f0fd4380d4cbd3a24660d0eec8"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.3"

[[deps.Compat]]
deps = ["UUIDs"]
git-tree-sha1 = "8a62af3e248a8c4bad6b32cbbe663ae02275e32c"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.10.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.5+0"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "8da84edb865b0b5b0100c0666a9bc9a0b71c553c"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.15.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "DataStructures", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrecompileTools", "PrettyTables", "Printf", "REPL", "Random", "Reexport", "SentinelArrays", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "04c738083f29f86e62c8afc341f0967d8717bdb8"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.6.1"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3dbd312d370723b6bb43ba9d02fc36abade4518d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.15"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "9f00e42f8d99fdde64d40c8ea5d14269a2e2c1aa"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.21"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GZip]]
deps = ["Libdl"]
git-tree-sha1 = "8d838ee3772e00c75d6cc06bb08891379868c18d"
uuid = "92fee26a-97fe-5a0c-ad85-20a5f3185b63"
version = "0.5.2"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "9cc2baf75c6d09f9da536ddf58eb2f29dedaf461"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.LazilyInitializedFields]]
git-tree-sha1 = "410fe4739a4b092f2ffe36fcb0dcc3ab12648ce1"
uuid = "0e77f7df-68c5-4e49-93ce-4cd80f5598bf"
version = "1.2.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.10.11"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.21+4"

[[deps.OrderedCollections]]
git-tree-sha1 = "2e73fe17cac3c62ad1aebe70d44c963c3cfdc3e3"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.2"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "716e24b21538abc91f6205fd1d8363f39b442851"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.7.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.9.2"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "36d8b4b899628fb92c2749eb488d884a926614d3"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.3"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "03b4c25b43cb84cee5c90aa9b5ea0a78fd848d2f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00805cd429dcb4870060ff49ef443486c262e38e"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.1"

[[deps.PrettyTables]]
deps = ["Crayons", "LaTeXStrings", "Markdown", "Printf", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "6842ce83a836fbbc0cfeca0b5a4de1a4dcbdb8d1"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.2.8"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RegistryInstances]]
deps = ["LazilyInitializedFields", "Pkg", "TOML", "Tar"]
git-tree-sha1 = "ffd19052caf598b8653b99404058fce14828be51"
uuid = "2792f1a3-b283-48e8-9a74-f99dce5104f3"
version = "0.1.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "04bdff0b09c65ff3e06a05e3eb7b120223da3d39"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "5165dfb9fd131cf0c6957a3a7605dede376e7b63"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.0"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.9.0"

[[deps.StringManipulation]]
deps = ["PrecompileTools"]
git-tree-sha1 = "a04cabe79c5f01f4d723cc6704070ada0b9d46d5"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.3.4"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "5.10.1+6"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "cb76cf677714c095e535e3501ac7954732aeea2d"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.11.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
git-tree-sha1 = "49cbf7c74fafaed4c529d47d48c8f7da6a19eb75"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.10.1"
weakdeps = ["Random", "Test"]

    [deps.TranscodingStreams.extensions]
    TestExt = ["Test", "Random"]

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.WorkerUtilities]]
git-tree-sha1 = "cd1659ba0d57b71a464a29e64dbc67cfe83d54e7"
uuid = "76eceee3-57b5-4d4a-8e66-0e911cebbf60"
version = "1.6.1"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

# ╔═╡ Cell order:
# ╠═8d70b100-2df2-11ed-20da-8d38fabd643a
# ╠═352bb1f4-50f9-4450-a6f5-ca342eaaafe2
# ╠═66b19454-86e2-44ad-8367-c661acaaddd3
# ╠═1b20b0b3-c9fb-403f-87fa-9d85e8572a0d
# ╠═247afed8-478d-487d-a643-15ce64db4cbc
# ╠═fe53e49c-d4a9-4329-a1e2-c3f83de2a9c3
# ╠═882badc4-dd60-418d-82de-e8f4a4f4e401
# ╠═337aa6ea-e090-4f12-88f5-ea16a2b3d009
# ╠═34641f5f-bce1-4a04-af87-54e2ef7b515b
# ╠═116a60a0-347a-413b-977c-fd3a58e6e495
# ╠═2f45374c-63af-4e20-99f0-71ddea504a13
# ╠═5a05a5bb-69bc-44db-b41a-12e76144c969
# ╠═b559c02f-a356-4d34-aba8-f5752414b6a9
# ╠═6729abd8-3df3-4c6a-8ee6-2117751dbabe
# ╟─aa31dde3-fb6b-4518-ab58-3ad90444ec05
# ╟─0a2d6489-a563-4f47-84b1-98f3b9f29bd2
# ╟─4a8c6a62-ba76-4565-9062-6c79b9800f24
# ╠═a66932de-d79e-4544-ab4f-fbfe3a10eb9e
# ╠═139d3f82-2fb5-4d50-b426-c6c0136ab5d5
# ╠═85d985fa-4c03-40e9-99d6-6b0517d02d8a
# ╠═fb69f248-9b78-44f5-9cd7-8d49dc2c17c3
# ╠═2a3a7470-6520-43b9-9877-95c18379cae0
# ╠═d5b284e8-48e4-45ff-b60e-897441ec1a79
# ╠═6df36e65-b8e7-4aca-a916-2844e700f33e
# ╠═f0b251d4-c538-472b-9ce3-e2b1ea8d3481
# ╠═e1818210-c67c-420b-a4e1-64df56c64fc2
# ╠═3a04e925-7c34-4ef1-acbe-dea9199033d9
# ╠═76f026c3-3610-4fab-81b6-8380f35fb1c2
# ╠═b8592dff-07d0-4ae4-b69e-64cc74bd17cc
# ╠═5fcb704e-5878-4674-bc75-f4d4a70aed63
# ╠═e4570d9a-5fe4-4214-8da1-f6d4d0d79b83
# ╠═afb17c6b-fd9b-4b29-aea2-28bee8f4d2ea
# ╠═79fd7a4c-2637-4a73-9539-73d624f5a0d0
# ╠═d32adabf-5bdf-4622-ac42-f31bff1d007b
# ╠═1a18c3e7-aaf3-4a21-9a06-a94e37650f9a
# ╠═4252936f-5435-4d62-a5a2-c5dacc936c6f
# ╠═b31351ba-59e9-46e2-be48-09204c56c20d
# ╠═bacc149e-46c1-4fa9-8daa-86e119bf8399
# ╠═e1bff052-a0a2-41a4-ac75-495e6d2d62a9
# ╠═50aeef93-d2b6-464e-8aed-2fab5a6d172f
# ╠═1aebde1a-1221-43f4-8c3b-e7ae54c3528e
# ╠═da6c519b-f35b-48d2-a897-dbbe58a69711
# ╠═2161f2d2-858d-4edf-ae33-eca9d9ef4980
# ╠═14077034-878e-4bcd-9468-fb6f9141aaad
# ╠═05cf4427-ff70-473b-ab32-74ef28f26404
# ╠═57312b16-9296-40cb-ac9a-861f38433d44
# ╠═cae907f9-2976-4899-9070-8c433e541ef4
# ╠═b27c0478-6669-402d-ab60-dfb8edde788c
# ╠═1fa4d8c9-d631-4cbb-a1f8-9789b465af0d
# ╠═e447c427-e63b-464f-bbb4-4d2104f2a32e
# ╠═43223cc7-3af8-4780-a5cc-289b31851fee
# ╠═fee23f41-5427-440f-8e3c-9a4509873219
# ╠═f0fa3338-bd47-4841-8f9b-4723ed00b30c
# ╠═f2fb2e4f-5862-49d4-9fc1-a15f76e2da48
# ╠═b5ba884e-fd95-4131-b1ee-dfcefcbdf3af
# ╠═876da4cd-23e4-4caa-ae8f-e32d994f8f20
# ╠═8bef7abd-963c-4edf-aca2-bbcbf22099cf
# ╠═75f9cb1d-85c5-4c2b-82e4-bcba298ca950
# ╠═94c2ae47-7350-42e8-abb9-7be7e624110a
# ╠═9836a44e-2eab-4e4d-be75-2e7d801198c7
# ╠═00000000-0000-0000-0000-000000000001
# ╠═00000000-0000-0000-0000-000000000002
