# -*- coding: utf-8; mode: makefile-gmake -*-

.DEFAULT = help
DEBUG ?= --pdb
TEST ?= .
EXT_DEBUG ?=

# python version to use
PY       ?=3
# list of python packages (folders) or modules (files) of this build
PYOBJECTS = M2Crypto
# folder where the python distribution takes place
PYDIST   ?= dist
# folder where the python intermediate build files take place
PYBUILD  ?= build

SYSTEMPYTHON = `which python$(PY) python | head -n 1`
VIRTUALENV   = virtualenv --python=$(SYSTEMPYTHON)
VTENV_OPTS   = "--no-site-packages"
TEST_FOLDER  = ./tests

ENV     = ./local/py$(PY)
ENV_BIN = $(ENV)/bin

SWIG = swig

PHONY += help
help::
	@echo  'usage:'
	@echo
	@echo  '  build     - build virtualenv ($(ENV)) and install *developer mode*'
	@echo  '  lint      - run pylint within "build" (developer mode)'
	@echo  '  test      - run tests for all supported environments (tox)'
	@echo  '  debug     - run tests within a PDB debug session'
	@echo  '  dist      - build packages in "$(PYDIST)/"'
	@echo  '  pypi      - upload "$(PYDIST)/*" files to PyPi'
	@echo  '  clean	    - remove most generated files'
	@echo
	@echo  'options:'
	@echo
	@echo  '  PY=3      - python version to use (default 3)'
	@echo  '  TEST=.    - choose test from $(TEST_FOLDER) (default "." runs all)'
	@echo  '  DEBUG=    - target "debug": do not invoke PDB on errors'
	@echo  '  EXT_DEBUG - target "build": compile extension with debug symbols.'
	@echo
	@echo  'When using target "debug", set breakpoints within py-source by adding::'
	@echo  '    ...'
	@echo  '    DEBUG()'
	@echo  '    ...'
	@echo
	@echo  'Example; a clean and fresh build (in local/py3), run all tests (py27, py35, lint)::'
	@echo
	@echo  '  make clean build test'
	@echo
	@echo  'Example; debug "test_engine.py" within a python2 session (in local/py2)::'
	@echo
	@echo  '  make PY=2 EXT_DEBUG=1 TEST=test_engine.py clean build test'


PHONY += build
build: swig-exe $(ENV)
	$(ENV_BIN)/python setup.py build_ext
	EXT_DEBUG=$(EXT_DEBUG) $(ENV_BIN)/pip install -e .

PHONY += lint
lint: $(ENV)
	$(ENV_BIN)/pylint $(PYOBJECTS) --rcfile pylintrc

PHONY += test
test:  $(ENV)
	$(ENV_BIN)/tox -vv

# e.g. to run tests in debug mode in emacs use:
#   'M-x pdb' ... 'make debug'

PHONY += debug
debug: build
	DEBUG=$(DEBUG) $(ENV_BIN)/pytest $(DEBUG) -v $(TEST_FOLDER)/$(TEST)

#gdb:  build
#	gdb -i=mi $(ENV_BIN)/bin/python

$(ENV):
	$(VIRTUALENV) $(VTENV_OPTS) $(ENV)
	$(ENV_BIN)/pip install -r requirements.txt

# for distribution, use python from virtualenv
PHONY += dist
dist:  swig-exe clean-dist $(ENV)
	$(ENV_BIN)/python setup.py \
		build_ext \
		bdist_wheel --bdist-dir $(PYBUILD) -d $(PYDIST)

PHONY += pypi
pypi: dist
	$(ENV_BIN)/twine upload $(PYDIST)/*

PHONY += clean-dist
clean-dist:
	rm -rf ./$(PYBUILD) ./$(PYDIST)


PHONY += clean
clean: clean-dist
	rm -rf ./local
	rm -rf *.egg-info .cache
	rm -rf .eggs .tox html
	rm -f MANIFEST .coverage \
	    tests/randpool.dat tests/sig.p7 tests/sig.p7s \
	    tests/tmp_request.pem \
	    tests/tmpcert.pem
	rm -f SWIG/_m2crypto_wrap.c M2Crypto/*m2crypto*.so M2Crypto/*m2crypto*.pyd
	find . -name '*~' -exec echo rm -f {} +
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*.so' -exec rm -f {} +
	find . -name __pycache__ -exec rm -rf {} +


msg-swig-exe:
	@echo "\n  $(SWIG) is required\n\n\
  Make sure you have an $(SWIG) installed, grab it from\n\
  http://swig.org or install it from your package\n\
  manager. On debian based OS these requirements are\n\
  installed by::\n\n\
    sudo apt-get install swig\n"

ifeq ($(shell which $(SWIG) >/dev/null 2>&1; echo $$?), 1)
swig-exe: msg-swig-exe
	$(error The '$(SWIG)' command was not found)
else
swig-exe:
	@:
endif

# END of Makefile
.PHONY: $(PHONY)
