#
# Tests for maintenance scripts.
#

.PHONY: all check clean

all::
	@(echo If you want to run the Scripts testsuite, please type \'make check\')

check::
	python3 -m py_compile ../*.py

clean::
	rm -rf __pycache__ ../__pycache__
