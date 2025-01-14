from benchutils import metrics, plotting, transformers

# TODO move to config
filename = "anonymous_reads"
(SIM, DT, NUM, _) = glob_wildcards("data/simulations/{simname}/{datetime}_sample_{sample_num}/reads/" + filename + ".{extension}")

SIM = sorted(set(SIM))
DT = sorted(set(DT))
NUM = sorted(set(NUM))

# TODO move to config
METHODS = ["kraken2", "metaphlan2"] # "shogun"]

# TODO move to config
METRICS = ['correlation', 'l2_norm', 'auprc', 'absolute_error']

# TODO move to config
METRIC_COMPARISONS1 = ['l2_norm', 'absolute_error']
# TODO move to config
METRIC_COMPARISONS2 = ['absolute_error', 'correlation']

RANKS = config["ranks"]

# TODO benchmarks for memory/time on rules (particularly assignment methods)

localrules: all, all_plots, all_metric_plots, unzip


rule all:
    # TODO input can understand if/else, could be useful for only including some parts of pipeline
    input:
        expand("analyses/{simname}/{datetime}_sample_all.{rank}.{metric}.done",
               simname=SIM,
               datetime=DT,
               rank=RANKS,
               metric=METRICS)


rule all_plots:
    input:
        expand("analyses/{{simname}}/{{datetime}}_sample_{sample_num}.{{rank}}.{{metric}}.done", sample_num=NUM),
        expand("analyses/{{simname}}/plots/{{datetime}}_sample_all.{{rank}}.{metric}.svg", metric=METRICS)
    output:
        temp("analyses/{simname}/{datetime}_sample_all.{rank}.{metric}.done")
    shell:
        """
        echo '' > {output}
        """


rule all_metric_plots:
    input:
        expand("analyses/{{simname}}/plots/{{datetime}}_sample_{{sample_num}}.{{rank}}.{metric1}_vs_{metric2}.svg", zip, metric1=METRIC_COMPARISONS1, metric2=METRIC_COMPARISONS2)
    output:
        temp("analyses/{simname}/{datetime}_sample_{sample_num}.{rank}.{metric}.done")
    shell:
        """
        echo '' > {output}
        """

rule metric_comparison_plotting:
    input:
        file1 = expand("analyses/{{simname}}/summaries/{{datetime}}_sample_{{sample_num}}.{{rank}}.{metric}.txt", metric=METRIC_COMPARISONS1),
        file2 = expand("analyses/{{simname}}/summaries/{{datetime}}_sample_{{sample_num}}.{{rank}}.{metric}.txt", metric=METRIC_COMPARISONS2)
    output:
        expand("analyses/{{simname}}/plots/{{datetime}}_sample_{{sample_num}}.{{rank}}.{metric1}_vs_{metric2}.svg", zip, metric1=METRIC_COMPARISONS1, metric2=METRIC_COMPARISONS2)
    run:
        for file1, file2, out_file in zip(input.file1, input.file2, output):
            plotting.metric_comparison_plot(file1, file2, out_file)

rule method_comparison_plotting:
    input:
        expand("analyses/{{simname}}/summaries/{{datetime}}_sample_{sample_num}.{{rank}}.{{metric}}.txt", sample_num=NUM)
    output:
        "analyses/{simname}/plots/{datetime}_sample_all.{rank}.{metric}.svg"
    run:
        plotting.method_comparison_plot(input, str(output))


rule benchmark_metrics:
    input:
        true_profile = "data/simulations/{simname}/taxonomic_profile_{sample_num}.txt",
        obs_profiles = expand("analyses/{{simname}}/profiles/{method}/{{datetime}}_sample_{{sample_num}}.{{rank}}.profile.txt", method=METHODS)
    output:
        expand("analyses/{{simname}}/summaries/{{datetime}}_sample_{{sample_num}}.{{rank}}.{metric}.txt", metric=METRICS)
    run:
        for metric, out_file in zip(METRICS, output):
            metrics.profile_error(input.obs_profiles, input.true_profile, out_file, wildcards.rank, methods=METHODS, metric=metric)


rule kraken2_transformer:
    input:
        "analyses/{simname}/profiles/kraken2/{datetime}_sample_{sample_num}._all.profile.txt"
    output:
        expand("analyses/{{simname}}/profiles/kraken2/{{datetime}}_sample_{{sample_num}}.{rank}.profile.txt", rank=RANKS)
    run:
        transformers.kraken2_transformer(str(input), output, ranks=RANKS)


rule kraken2:
    input:
        "data/simulations/{simname}/{datetime}_sample_{sample_num}/reads/" + filename + ".fq"
    output:
        all = "analyses/{simname}/profiles/kraken2/{datetime}_sample_{sample_num}._all.profile.txt",
    conda:
        "envs/taxa-benchmark.yml"
    shell:
        "kraken2 --db {config[kraken_db]} --use-names --report {output.all} {input}"


rule metaphlan2_transformer:
    input:
        "analyses/{simname}/profiles/metaphlan2/{datetime}_sample_{sample_num}._all.profile.txt",
    output:
        expand("analyses/{{simname}}/profiles/metaphlan2/{{datetime}}_sample_{{sample_num}}.{{rank}}.profile.txt", rank=RANKS)
    run:
        transformers.metaphlan2_transformer(str(input), output, ranks=RANKS)


rule metaphlan2:
    input:
        "data/simulations/{simname}/{datetime}_sample_{sample_num}/reads/" + filename + ".fq"
    output:
        "analyses/{simname}/profiles/metaphlan2/{datetime}_sample_{sample_num}._all.profile.txt",
    resources:
        mem_gb=64
    conda:
        "envs/taxa-benchmark.yml"
    shell:
        """
        rm -f {input}.bowtie2out.txt
        # compute metaphlan2 output for all tax levels
        metaphlan2.py {input} --input_type fastq --tax_lev 'a' > {output}        
        """


rule shogun:
    # TODO finish rule
    input:
        "data/simulations/{simname}/{datetime}_sample_{sample_num}/reads/" + filename + ".fq"
    output:
        expand("analyses/{{simname}}/profiles/shogun/{{datetime}}_sample_{{sample_num}}.{{rank}}.profile.txt", rank=RANKS)
    conda:
        "envs/taxa-benchmark.yml"
    shell:
        "touch {output}"


rule unzip:
    input:
        "data/simulations/{simname}/{datetime}_sample_{sample_num}/reads/" + filename + ".fq.gz"
    output:
        "data/simulations/{simname}/{datetime}_sample_{sample_num}/reads/" + filename + ".fq"
    shell:
        "gunzip {input}"

