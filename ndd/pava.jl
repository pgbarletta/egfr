#!/usr/bin/env julia
###############################################################################
# Utility to displace a PDB along many vectors, generating 1 PDB for each
# vector, useful for NDD analsis.
# by https://github.com/pgbarletta
###############################################################################
using DataFrames
using MIToS.PDB
using Distributions
using ArgParse
##########
# functions
##########
function read_ptraj_modes(file, modes_elements, norma::Bool=true)
    modes_file = open(file, "r")
    modes_text = readdlm(modes_file, skipstart=0, skipblanks=true,
    ignore_invalid_chars=true, comments=true, comment_char='\*')
    close(modes_file)

    nmodes = modes_text[1, 5]
    ncoords = convert(Int64, modes_elements)
    lines = ceil(Int64, ncoords/7)
    rest = convert(Int64, ncoords % 7)

    eval = Array{Float64}(nmodes);
    mode = Array{Float64}(ncoords, nmodes);
    temp1 = Array{Float64}(ncoords, 1);
    temp2 = Array{Float64}(ncoords+(7-rest));

    j = lines + 1 + 2 # 1 p/ q lea la prox linea 2 por el header

    for i = 1:nmodes
        eval[i] = modes_text[j, 2]
        temp = transpose(modes_text[(j+1):(lines+j), :])
        temp2 = reshape(temp, ncoords+(7-rest))
        for k=(rest+1):7
            pop!(temp2)
        end
    mode[:, i] = temp2
        j = j + lines + 1
    end

    if norma == true
        for i=1:nmodes
            mode[: ,i] = mode[:, i] / norm(mode[:, i])
        end
    end

    return mode, eval
end
#########
function displaceAA(mod_pdb, in_vector, multiplier)
	# Preparo variables
    pdb = copy(mod_pdb)
    struct_xyz = coordinatesmatrix(pdb)
    new_struct_xyz = copy(struct_xyz)
   	aa = length(pdb)
	# Determino el nro de atomos de c/ aminoácido
	natom = Array{Int64}(aa)
	[ natom[i] = length(pdb[i]) for i = 1:aa ]
  	# Adapto el vector p/ darle la misma forma q la matriz de coordenadas
	vector = Array{Float64}
	const tmp_size = size(in_vector)
        const natoms = sum(natom)

	if tmp_size == (aa*3, )
		vector = transpose(reshape(in_vector, 3, aa))
	elseif tmp_size == (aa, 3)
		vector = in_vector
	else
		error("Input vector with wrong dimensions: ", tmp_size, "  ", (aa*3, 1))
	end
	sum_mat = Array{Float64}(sum(natom),3)
	cursor = 0
   	for i = 1:aa
		rango = Array{Int64}(natom[i])
    	if i == 1
			sum_mat[1:natom[i], :] = repmat(transpose(vector[i, :]),
				natom[i], 1)
			cursor = natom[i]
			continue
		end
		rango = collect(cursor+1:cursor + natom[i])
		sum_mat[rango, :] = repmat(transpose(vector[i, :]), natom[i], 1)
		cursor += natom[i]
	end

   # Listo, ahora puedo mover el pdb
   new_struct_xyz  = struct_xyz + sum_mat .* multiplier
   pdb = change_coordinates(pdb, new_struct_xyz);
   return pdb
end
#########
function displaceAtoms(mod_pdb, vector1, multiplier)
  # Preparo variables
    pdb = copy(mod_pdb)
    struct_xyz = coordinatesmatrix(pdb)
#    new_struct_xyz = copy(struct_xyz)
    vector = Array{Float64}(1, 3)

    # Adapto el vector p/ darle la misma forma q la matriz de coordenadas
    for i = 1:3:length(vector1)
        if i== 1
            vector = reshape(vector1[i:i+2], 1, 3)
            continue
        end
        vector = vcat(vector, reshape(vector1[i:i+2], 1, 3))
    end

    # Listo, ahora puedo mover el pdb
    new_struct_xyz  = struct_xyz + vector .* multiplier
    pdb = change_coordinates(pdb, new_struct_xyz);
   return pdb
end
#########
# Arg Parse settings
s = ArgParseSettings()
@add_arg_table s begin
    "--in_pdb_filename", "-p"
        help = "Input PDB."
        arg_type = String
        required = true
    "--modes_filename", "-v"
        help = "Input modes."
        arg_type = String
        required = true
    "--mul", "-m"
        help = "Multiplier."
        arg_type = Int
        required = true
    "--outpdb", "-o"
        help = "Output PDBs suffix"
        arg_type = String
        required = true
    "--amber_modes", "-a"
        help = "Mark true when reading from Amber PCA modes kind of file"
                "Default: false."
        arg_type = Bool
        required = false
        default = false
    "--weights_filename", "-v"
        help = "Input weights, if desired. Default: none"
        arg_type = String
        required = false
        default = "none"
end

##########
# main program
##########

# Read arguments from console
parsed_args = parse_args(ARGS, s)
args = Array{Any, 1}(0)
for (arg, val) in parsed_args
    arg = Symbol(arg)
    @eval (($arg) = ($val))
end
# Append ".pdb" to output pdb
outpdb = outpdb * ".pdb"

println("Input parameters:")
println("INPDB          ", in_pdb_filename)
println("VECTORS        ", modes_filename)
println("WEIGHTS        ", weights_filename)
println("MUL            ", mul)
println("OUTPDB         ", outpdb)

# Read PDB
in_pdb = read(string(in_pdb_filename), PDBFile, group="ATOM");
aa = 3 * length(in_pdb)
aa_3 = 3 * aa
natom_xyz = size(coordinatesmatrix(in_pdb))[1] * 3

in_vec = Array{Float64}
# Modos de PCA Amber
    try
        in_vec = read_ptraj_modes(vector_filename,
			aa_3, true)[1][:, index]
    catch
        try
            in_vec = read_ptraj_modes(vector_filename,
				natom_xyz, true)[1][:, index]
        end
    end
	in_vec = convert(Array{Float64}, readdlm(vector_filename))

# In case input vector file is not found
if in_vec == Array{Float64, 1}
    error(ArgumentError(string("\n\n", modes_filename, " could not be found.")))
end

# Ahora desplazo
cnt = 0
if aa_3 == length(in_vec)
# El modo es de Calpha y está ordenado en una columna
    in_vec = in_vec / norm(in_vec)
    for step in -top:resolution:top
        out_pdb = displaceAA(in_pdb, in_vec, step);
        # Y guardo
        cnt+=1
        out_filename = string(cnt, "_", outpdb)
        write(out_filename, out_pdb, PDBFile)
    end
elseif natom_xyz == length(in_vec)
# El modo es all-atom
    in_vec = in_vec / norm(in_vec)

    for step in -top:resolution:top
        out_pdb = displaceAtoms(in_pdb, in_vec, step);
        # Y guardo
        cnt+=1
        out_filename = string(cnt, "_", outpdb)
        write(out_filename, out_pdb, PDBFile)
    end

else
# El modo no tiene el tamaño adecuado
error("PDB and input vector don't match.\nPDB has ", length(in_pdb) ,
" amino acids and ", size(coordinatesmatrix(in_pdb))[1] * 3, " atoms.\nVector has ",
length(in_vec), " elements, which should correspond to ", length(in_vec) / 3, " particles.")
end


# Finalmente, hago el script. Esto va p/ casos en los q haga 1 solo
# desplazamiento
if script == true
	f = open("script_porky.py", "w")
	load = "cmd.load(\""

	write(f, "from pymol.cgo import *\n")
    write(f, "from pymol import cmd\n\n")

	write(f, "cmd.set(\"cartoon_fancy_helices\", 1)\n")
	write(f, "cmd.set(\"cartoon_transparency\", 0.5)\n")
    write(f, "cmd.set(\"two_sided_lighting\", \"on\")\n")
    write(f, "cmd.set(\"reflect\", 0)\n")
    write(f, "cmd.set(\"ambient\", 0.5)\n")
    write(f, "cmd.set(\"ray_trace_mode\",  0)\n")
    write(f, "cmd.set('''ray_opaque_background''', '''off''')\n")

	write(f, load, in_pdb_filename,"\")\n")
	write(f, load, string(cnt, "_", outpdb),"\")\n")
	write(f, load,"modevectors.py\")\n")
	write(f, "modevectors(\"", in_pdb_filename[1:end-4], "\", \"", string(cnt, "_", outpdb)[1:end-4], "\", ")
	write(f, "outname=\"modevectors\", head=0.5, tail = 0.3, cut=0.5, headrgb = \"1.0, 1.0, 0.0\", tailrgb = \"1.0, 1.0, 0.0\") ")

	close(f)
end