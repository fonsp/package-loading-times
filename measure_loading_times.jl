import Pkg
Pkg.activate(;temp=true)

lines = readlines("top_packages_sorted_with_deps.txt")

# test
lines = lines[1:50]




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


filename = "pkg_load_times.csv"

file_output = Ref("name,install_time,load_time1,load_time2\n")




for line in lines
    package, deps... = split(line,",")
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
        # @info "c"
        # c = @elapsed Pkg.precompile()
        
        function load_time()
            cmd = `julia --project=$(Base.load_path()[1] |> dirname) -e $(
                """
                $(join(("import $(dep); " for dep in deps)))
                t = @elapsed import $(package);
                print(t);
                exit();
                """
            )`
             
            output = try
                read(cmd, String)
            catch
                ""
            end
            something(tryparse(Float64, output), NaN)
        end
        
        @info "First load time"
        load_time1 = load_time()
        
        @info "Second load time"
        load_time2 = load_time()
        
        
        @info "time" install_time load_time1 load_time2
        
        file_output[] *= "$(package),$install_time,$load_time1,$load_time2\n"
        write(filename, file_output[])
    catch e
        @error "Failed to do package!" package exception=(e, catch_backtrace())
        
        file_output[] *= "$(package),NaN,NaN,NaN\n"
        write(filename, file_output[])
    end
        
end
