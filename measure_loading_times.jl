
@warn "Reminder: you need to manually clear your `.julia` caches for this script to work. See comment below."



# for p in [
#     "$(DEPOT_PATH |> first)/compiled/v1.$(VERSION.minor)/$(name)" 
#     "$(DEPOT_PATH |> first)/packages/$(name)"
# ]
#     isdir(p) && rm(p, recursive=true)
# end



# for p in [
#     "$(DEPOT_PATH |> first)/compiled/v1.$(VERSION.minor)" 
#     "$(DEPOT_PATH |> first)/packages"
#     "$(DEPOT_PATH |> first)/artifacts"
#     "$(DEPOT_PATH |> first)/scratchspaces"
# ]
#     isdir(p) && rm(p, recursive=true)
# end

# ➜  Documents sudo rm -rf ~/.julia/artifacts
# Password:
# ➜  Documents sudo rm -rf ~/.julia/scratchspaces 
# ➜  Documents sudo rm -rf ~/.julia/compiled/v1.8
# ➜  Documents sudo rm -rf ~/.julia/packages  



import Pkg
import TOML
import Dates
using InteractiveUtils
Pkg.activate(;temp=true)

ENV["JULIA_PKG_PRECOMPILE_AUTO"] = "false"


mkpath("output")

lines = readlines(joinpath("output", "top_packages_sorted_with_deps.txt"))


# We add Pkg.jl at the start, this will "take the blame" for the JIT overhead of calling Pkg.add & Pkg.precompile etc.
lines = ["Pkg", lines...]



data = Dict{String,Any}()

d(x,y,z,v) = Dict(
    "install_time" => x,
    "precompile_time" => y,
    "load_time1" => z,
    "version" => v,
)

peakflops_result = peakflops()
start_time = Dates.now()
jloptions = try
    Base.JLOptions() |> string
catch
    ""
end

filename = joinpath("output", "pkg_load_times.toml")
function submit()
    s = sprint() do io
        TOML.print(io, Dict(
            "time" => start_time,
            "julia_version" => string(VERSION),
            "versioninfo" => sprint(versioninfo),
            "machine" => string(Sys.MACHINE),
            "os" => Sys.iswindows() ? "Windows" : Sys.isapple() ? "macOS" : string(Sys.KERNEL),
            "peakflops" => peakflops_result,
            "jloptions" => jloptions,
            "version" => 1,
            "results" => data,
        ))
    end
    
    write(filename, s)
end



for (i,line) in enumerate(lines)
    package, deps... = split(line,",")
    filter!(!isequal("julia"), deps)

    try
        @info "# New package" package deps
        
        Pkg.activate(;temp=true)
        isempty(deps) || Pkg.add(deps)
        Pkg.instantiate()
        Pkg.precompile()
        
        @info "Install time"
        install_time = @elapsed Pkg.add(package)
        # @info "b"
        # b = @elapsed Pkg.instantiate(; allow_autoprecomp=false)
        @info "Precompile time"
        precompile_time = @elapsed Pkg.precompile()
        
        function load_time()
            cmd = `julia --project=$(Base.load_path()[1] |> dirname) -e $(
                """
                $(join(("import $(dep); " for dep in deps)))
                t = @elapsed import $(package);
                print(repr((
                    time=t,
                    version=isdefined(Base, :pkgversion) ? Base.pkgversion($(package)) : nothing,
                )));
                exit();
                """
            )`
             
            output = try
                read(cmd, String)
            catch
                ""
            end
            try
                eval(Meta.parse(output))
            catch
                (time=NaN, version=nothing)
            end
        end
        
        @info "First load time"
        load_time1, loaded_version = load_time()
        
        # @info "Second load time"
        # load_time2 = load_time()
        # (I found that this always equals load_time1)
        
        
        
        
        @info "time" install_time precompile_time load_time1 loaded_version
        
        data[package] = d(install_time, precompile_time, load_time1, string(loaded_version))
        submit()
    catch e
        @error "Failed to do package!" package exception=(e, catch_backtrace())
        
        data[package] = d(NaN, NaN, NaN, string(nothing))
        submit()
    end
        
end
