RST := \033[m
BLD := \033[1m
RED := \033[31m
GRN := \033[32m
YLW := \033[33m
BLU := \033[34m
EOL := \n

all: ami
	@printf '${BLD}${RED}make: *** [$@]${RST}${EOL}'
.PHONY: all

ami:
	@printf '${BLD}${RED}make: *** [$@]${RST}${EOL}'
	@printf '${BLD}${YLW}$$${RST} '
	PACKER_LOG=1 packer init -upgrade .
	@printf '${BLD}${YLW}$$${RST} '
	packer build macami.pkr.hcl
.PHONY: ami
