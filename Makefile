.PHONY: all analysis test article

all: analysis test article

analysis:
	Rscript run.R

test:
	Rscript -e 'testthat::test_dir("tests/testthat")'

article:
	python manuscript/build_docx.py
