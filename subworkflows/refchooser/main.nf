// Subworkflow to run MUmmer for query/referece comparisons
// Params are passed from Yenta.nf or from the command line if run directly

// Set output paths
if(params.outroot == ""){
    output_directory = file("${params.out}")
} else{
    output_directory = file("${file("${params.outroot}")}/${params.out}")
}

assembly_directory = file("${output_directory}/Assemblies")
assembly_file = file("${output_directory}/Assemblies/Assemblies.txt")

n_ref = params.n_ref.toInteger()

// Set modules if necessary
params.refchooser_module = ""
if(params.refchooser_module == ""){
    params.load_refchooser_module = ""
} else{
    params.load_refchooser_module = "module load -s ${params.refchooser_module}"
}

workflow runRefChooser{
    take:
    sample_data

    emit:
    reference_data

    main:
    
    // Get reference isolate
    hold_file = sample_data | writeAssemblyPath | collect | flatten | first 
    
    ref_path = refChooser(hold_file,n_ref) | splitCsv

    sample_data.flatMap { sample ->
        ref_paths.map { ref_path ->
            tuple(sample[0], sample[1], sample[2], sample[3], ref_path)
        }
    } | filter { tuple ->
        tuple[3] == tuple[4] // Filter based on your condition
    } | map { tuple ->
        tuple(tuple[0], tuple[1], tuple[2], tuple[3])
    } into reference_data

    reference_data.subscribe{println("Final_Ref: $it")}
}

process refChooser{
    
    executor = 'local'
    cpus = 1
    maxForks = 1

    input:
    val(assembly_file)
    val(n_ref)

    output:
    stdout

    script:

    head_count = n_ref + 1

    """
    $params.load_refchooser_module
    cd $assembly_directory

    refchooser metrics --sort Score $assembly_file sketch_dir > refchooser_results.txt

    column_data=\$(head -$head_count refchooser_results.txt | tail -$n_ref | cut -f7)

    if [[ \$(wc -l <<< "\$column_data") -gt 1 ]]; then
        echo "\$column_data" | paste -sd ',' -
    else
        echo "\$column_data"
    fi
    """
}

process writeAssemblyPath{
    executor = 'local'
    cpus = 1
    maxForks = 1
    
    input:
    tuple val(sample_name),val(data_type),val(read_location),val(assembly_location)

    output:
    val(assembly_file)

    script:
    """
    echo "${assembly_location}" >> $assembly_file
    """
}