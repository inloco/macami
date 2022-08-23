RST := $(shell tput sgr0)
BLD := $(shell tput bold)
RED := $(shell tput setaf 1)
GRN := $(shell tput setaf 2)
YLW := $(shell tput setaf 3)
BLU := $(shell tput setaf 4)
EOL := \n

all: ami
	@printf '${BLD}${RED}make: *** [$@]${RST}${EOL}'
.PHONY: all

ami:
	@printf '${BLD}${RED}make: *** [$@]${RST}${EOL}'
	@printf '${BLD}${YLW}$$${RST} '
	packer init -upgrade .
	@printf '${BLD}${YLW}$$${RST} '
	packer build macami.pkr.hcl
.PHONY: ami
