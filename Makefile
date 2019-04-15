NAME := ulb
FILE := $(NAME).sh
PREFIX := /usr/local/bin

$(NAME): clean
	@test -f $(FILE) && cp $(FILE) $(NAME) && chmod 777 $(NAME)

.PHONY: clean install uninstall

clean:
	$(RM) $(NAME)

install:
	cp -i $(NAME) $(PREFIX)

uninstall:
	$(RM) -i $(PREFIX)/$(NAME)
