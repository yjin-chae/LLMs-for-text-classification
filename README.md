# Replication materials for Large Language Models for Text Classification: From Zero-Shot Learning to Instruction-Tuning

Last edited 12/12/2024

This repository contains replication materials for Youngjin (YJ) Chae and Thomas Davidson. 2025. "Large Language Models for Text Classification: From Zero-Shot Learning to Instruction-Tuning." *Sociological Methods & Research.* (https://journals.sagepub.com/doi/10.1177/00491241251325243).

Please get in touch via email if you have any questions.

# Version information

Many of the models used in this analysis require one or more GPUs. Most analyses were performed on the [Amarel high-performance computing cluster](https://oarc.rutgers.edu/resources/amarel/) at Rutgers University, a Linux-based environment consisting of a large cluster of compute nodes that can be used to execute processes in parallel. The GPT-3 and GPT-4o analyses were performed using the [OpenAI API](https://platform.openai.com/docs/overview).

# Codebase
The following sections detail the organization of the data and processes for data cleaning, the estimation of the models, and the construction of the results.

At a high-level, our analyses can be replicated by running the scripts to generate training data, running the models, and then finally generating the figures and tables (`tables-and-plots`). We have also provided the full output (predicted labels) from the models so the final results can be reproduced simply by using these files to produce the figures and tables without needing to perform the time-consuming and costly estimation steps.

## Data

The following describes the data sources used in the analyses. See the following section for instructions on running the scripts to generate the final analysis data. All data are stored in the `data` folder. 

### Twitter data (SemEval 2016)
This dataset is a version of the SemEval stance prediction task. Each tweet is annotated with stances towards either Donald Trump or Hillary Clinton. The original dataset is available [here](https://alt.qcri.org/semeval2016/task6/). 

### Facebook comment data
This dataset is an original set of Facebook comments from the pages of Donald Trump and Hillary Clinton during the 2016 US presidential campaign. Each comment is a top-level comment made on a post by one of the candidates and is annotated with stances towards both Trump and Clinton.

### Facebook comment-thread data
This dataset is drawn from the same set of comments as the other comment data. Each thread represents a top-level comment on a post by one of the candidates with up to five replies. The threads also include information on the page, the original post, and pseudonyms corresponding to each author.

## Replication steps

### Processing the data
To split the data into training and test sets and to extract few-shot exemplars, run `1.data_preparation_{task}.ipynb`.

### Running the models

The scripts are arranged according to the models listed in the paper. Each script can be used to run the entire set of analyses. There are two exceptions. The `6.Facebook_thread.ipynb` script has code to run the thread-level prediction task for all three models used (Llama3 8B, Llama3 70B, and GPT-4o). Note that code for GPT3 (`2.GPT3_{task}.ipynb`) will no longer work because these models have been deprecated in the OpenAI API (see paper for further discussion). We left the legacy code for reference. The `3.GPT4o_{task}.ipynb` code will work using a more recent model, but it is possible this model will be deprecated as the technologies advance.

With the exception of the OpenAI models, all other models are downloaded from [Hugging Face](https://huggingface.co/models) and are fine-tuned using the `transformer` library in Python. Please note that the models used in this analysis are stochastic and there is no guarantee that exact results will be reproduced if the training or prediction process is repeated. However, we expect the general results will be relatively stable.

### Producing the output
Once the training and test sets have been generated, running each script in the main directory will generate and save predicted labels in `predicted_labels/`. Note that zero- and one-shot tasks can produce outputs in various formats and some outputs have been cleaned to align them with the label schema. The `7.Bootstrap_score_calculation.ipynb` script calculates bootstrapped F1, precision, and recall scores using these labels and save the scores in `tables_and_plots/raw_scores`. Finally, the scripts in `tables_and_plots` will produce the various figures and tables in the paper and supplemental materials. Since predicted labels are provided, the final results can be reproduced without retraining the models.
