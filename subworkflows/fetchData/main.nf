// Subworkflow to fetch sample and reference data, assembling reads into genomes using SKESA if necessary
// Params are passed from Yenta.nf or from the command line if run directly

// Set output paths
params.out = "./YENTA_${new java.util.Date().getTime()}"
output_directory = file("${params.out}")
reference_directory = file("${output_directory}/Reference_Strain_Data")

// Set cores
params.cores = 1

// Set data location
params.reads = ""
params.fasta = ""
params.ref_reads = ""
params.ref_fasta = ""

// Set data type (Default: srazip)
params.readtype = ""
params.ref_readtype = ""

if(params.readtype){
    if(params.readtype == "illumina"){
        params.readext = "fastq.gz"
        params.forward = "_R1_001.fastq.gz"
        params.reverse = "_R2_001.fastq.gz"
    } else if (params.readtype == "sra"){
        params.readext = "fastq"
        params.forward = "_1.fastq"
        params.reverse = "_2.fastq"
    } else if (params.readtype == "srazip"){
        params.readext = "fastq.gz"
        params.forward = "_1.fastq.gz"
        params.reverse = "_2.fastq.gz"
    } else{
        error "Invalid --readtype [ Options include illumina, sra, srazip (Default) ]"
    }
} else{
    params.readext = "fastq.gz"
    params.forward = "_1.fastq.gz"
    params.reverse = "_2.fastq.gz"
}
if(params.ref_readtype){
    if(params.ref_readtype == "illumina"){
        params.ref_readext = "fastq.gz"
        params.ref_forward = "_R1_001.fastq.gz"
        params.ref_reverse = "_R2_001.fastq.gz"
    } else if (params.ref_readtype == "sra"){
        params.ref_readext = "fastq"
        params.ref_forward = "_1.fastq"
        params.ref_reverse = "_2.fastq"
    } else if (params.ref_readtype == "srazip"){
        params.ref_readext = "fastq.gz"
        params.ref_forward = "_1.fastq.gz"
        params.ref_reverse = "_2.fastq.gz"
    } else{
        error "Invalid --ref_readtype [ Options include illumina, sra, srazip (Default) ]"
    }
} else{
    params.ref_readext = "fastq.gz"
    params.ref_forward = "_1.fastq.gz"
    params.ref_reverse = "_2.fastq.gz"
}

// Create module loading scripts if necessary
params.python_module = ""
params.skesa_module = ""

if(params.python_module == ""){
    params.load_python_module = ""
} else{
    params.load_python_module = "module load -s ${params.python_module}"
}
if(params.skesa_module == ""){
    params.load_skesa_module = ""
} else{
    params.load_skesa_module = "module load -s ${params.skesa_module}"
}

// Workflows //
workflow fetchSampleData{
    
    emit:
    sample_data

    main:

    // Collect paths to read/assembly data for samples
    ("${params.reads}" != "" ? getReads(params.reads,params.readext,params.forward,params.reverse) : Channel.empty()).set{sample_read_data}
    ("${params.fasta}" != "" ? getAssemblies(params.fasta) : Channel.empty()).set{sample_assembly_data}

    all_sample_data = sample_read_data.concat(sample_assembly_data) 
    
    sample_data = mergeDuos(all_sample_data,"Sample") | makeSampleFolder | splitCsv | assembleSamples
}
workflow fetchReferenceData{
    emit:
    reference_data

    main:
    
    // Collect paths to read/assembly data for references
    ("${params.ref_reads}" != "" ? getReads(params.ref_reads,params.ref_readext,params.ref_forward,params.ref_reverse) : Channel.empty()).set{reference_read_data}
    ("${params.ref_fasta}" != "" ? getAssemblies(params.ref_fasta) : Channel.empty()).set{reference_assembly_data}
    
    all_reference_data = reference_read_data.concat(reference_assembly_data)

    reference_data = mergeDuos(all_reference_data,"Reference") | assembleReference
}
workflow getReads{

    take:
    read_loc
    read_ext
    forward
    reverse

    emit:
    read_info
    
    main:

    if(read_loc == ""){
        error "No data provided to --reads/--ref_reads"
    } else{
        read_dir = file(read_loc)

        // If --reads is a single directory, get all reads from that directory
        if(read_dir.isDirectory()){
            read_info = fetchPairedReads(read_dir,read_ext,forward,reverse) 
            | splitCsv 
            | map{tuple(it[0].toString(),it[1].toString(),it[2].toString())}
        } 

        // If --reads is a file including paths to many directories, process reads from all directories
        else if(read_dir.isFile()){
            read_info = fetchPairedReads(Channel.from(read_dir.readLines()),read_ext,forward,reverse) 
            | splitCsv 
            | map{tuple(it[0].toString(),it[1].toString(),it[2].toString())}

        }
        // Error if --reads doesn't point to a valid file or directory
        else{
            error "$read_dir is neither a valid file or directory..."
        }
    }      
}
workflow getAssemblies{

    take:
    fasta_loc

    emit:
    fasta_data
    
    main:

    if(fasta_loc == ""){
        error "No assembly data provided via --fasta"
    } else{
        fasta_dir = file(fasta_loc)

        // If --fasta is a directory...
        if(fasta_dir.isDirectory()){
            ch_fasta = Channel.fromPath(["${fasta_dir}/*.fa","${fasta_dir}/*.fasta","${fasta_dir}/*.fna"])
        } 
        // If --fasta is a file...
        else if(fasta_dir.isFile()){
            // Check if it is a single fasta file...
            if(fasta_dir.getExtension() == "fa" || fasta_dir.getExtension() == "fna" || fasta_dir.getExtension() == "fasta"){
                ch_fasta = Channel.from(fasta_dir)
            } 
            // Otherwise, assume a file with paths to FASTAs
            else{
                ch_fasta = Channel.from(fasta_dir.readLines())
            }
        }
        else{
            error "$fasta_dir is not a valid directory or file..."
        }

        fasta_data = ch_fasta
        | map{tuple(file("$it").getBaseName(),"Assembly",file("$it"))} // Get the path and the name
    }
}
workflow mergeDuos{

    // Workflow to merge data that are provided as both reads and assembly

    take:
    isolate_data
    run_mode

    emit:
    merged_data
   
    main:

    // If reads and assemblies are provided, split data
    if(run_mode == "Sample"){
        split_data = isolate_data
        | branch{
            assembly: "${it[1]}" == "Assembly"
                return tuple(it[0],it[1],"",it[2])
            read: true
                return tuple(it[0],it[1],it[2],"${output_directory}/${it[0]}/${it[0]}.fasta")}
    } else if(run_mode == "Reference"){
        split_data = isolate_data
        | branch{
            assembly: "${it[1]}" == "Assembly"
                return tuple(it[0],it[1],"",it[2])
            read: true
                return tuple(it[0],it[1],it[2],"${reference_directory}/${it[0]}.fasta")}    
    } else{
        error "run_mode should be Sample or Reference, not $run_mode..."
    }

    // For any references with both read and assembly data, merge and create a single entry      
    split_data.read.join(split_data.assembly.map{it->tuple(it[0],it[3])},by:0).map{it-> tuple(it[0],"Duo_${it[1]}",it[2],it[4])}.ifEmpty{tuple("No_Duo","No_Duo","No_Duo","No_Duo")}.set{duo_data}
    duo_isolates = duo_data.map{it -> it[0]}.collect()
        
    merged_data = pruneDuos(duo_data.concat(split_data.read).concat(split_data.assembly),duo_isolates) | splitCsv()
}
workflow assembleSamples{
    take:
    sample_data

    emit:
    assembled_samples

    main:
    
    split_data = sample_data
    | branch{
        single: "${it[1]}" == "Single"
        paired: "${it[1]}" == "Paired"
        assembled: true
    }

    assembled_samples = runSKESA(split_data.single.concat(split_data.paired)) | splitCsv | concat(split_data.assembled)
}
workflow assembleReference{
    take:
    reference_data

    emit:
    assembled_reference

    main:

    split_data = reference_data
    | branch{
        single: "${it[1]}" == "Single"
        paired: "${it[1]}" == "Paired"
        assembled: true
    }

    assembled_reference = runSKESA(split_data.single.concat(split_data.paired)) | splitCsv | concat(split_data.assembled)
}

// Processes //
process fetchPairedReads{

    executor = 'local'
    cpus = 1
    maxForks = 1

    input:
    val dir // Directory containing read files
    val read_ext // Extention for read files (e.g., fastq.gz or fq)
    val forward_suffix // Identifier for forward reads (e.g., _1.fastq or _R1_001.fq.gz)
    val reverse_suffix // Identifier for reverse reads (e.g., _2.fastq or _R2_001.fq.gz)

    output:
    stdout

    script:
    
    // Set path to accessory script
    findPairedReads = file("${projectDir}/bin/fetchReads.py")

    """
    ${params.load_python_module}
    python ${findPairedReads} ${dir} ${read_ext} ${forward_suffix} ${reverse_suffix}
    """
}
process pruneDuos{
    executor = 'local'
    cpus = 1
    maxForks = 1

    
    input:
    tuple val(sample_name),val(data_type),val(read_location),val(assembly_location)
    val(duo_samples)

    output:
    stdout

    script:

    // If duo_data is "No_Duo", return nothing for first tuple
    if(sample_name == "No_Duo"){
        """
        echo
        """      
    } else if(duo_samples[0] == "No_Duo"){
        // If no duos exist, return sample data
        """
        echo -n "${sample_name},${data_type},${read_location},${assembly_location}"
        """ 
    } else{
        if( (sample_name in duo_samples) && (!data_type.startsWith("Duo_")) ){
            // Don't return individual data for duo samples
            """
            echo
            """
        } else{
            // Return samples without duos
            """
            echo -n "${sample_name},${data_type},${read_location},${assembly_location}"
            """
        }
    }
}
process makeSampleFolder{
    executor = 'local'
    cpus = 1
    maxForks = 1

    input:
    tuple val(sample_name),val(data_type),val(read_location),val(assembly_location)

    output:
    stdout
   
    script:
    
    sample_dir = file("${output_directory}/${sample_name}")
    mummer_dir = file("${sample_dir}/MUmmer")

    if(sample_dir.isDirectory()){
        error "$sample_dir already exists"
    } else if(!output_directory.isDirectory()){
        error "$output_directory doesn't exist"
    } else{
        """
        mkdir $sample_dir
        mkdir $mummer_dir
        echo "$sample_name,$data_type,$read_location,$assembly_location"
        """     
    }
}
process runSKESA{
    
    input:
    tuple val(sample_name),val(read_type),val(read_location),val(assembly_out)

    output:
    stdout

    script:

    assembly_file = file(assembly_out)
    assembly_dir = assembly_file.getParent()

    if(assembly_file.isFile()){
        error "$assembly_out already exists..."
    } else if(!assembly_dir.isDirectory()){
        error "$assembly_dir does not exist..."
    } else{
        if(read_type == "Paired"){
            forward_reverse = read_location.split(";")
            """
            $params.load_skesa_module
            skesa --use_paired_ends --fastq ${forward_reverse[0]} ${forward_reverse[1]} --contigs_out ${assembly_file} --cores ${params.cores}
            echo "$sample_name,$read_type,$read_location,$assembly_out"
            """
        } else if(read_type == "Single"){
            """
            $params.load_skesa_module
            skesa --fastq ${read_location} --contigs_out ${assembly_file} --cores ${params.cores}
            echo "$sample_name,$read_type,$read_location,$assembly_out"
            """
        } else{
            error "read_type should be Paired or Single, not $read_type..."
        }
    }
}