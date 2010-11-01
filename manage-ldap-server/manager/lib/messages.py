#!/usr/bin/env python

def message(message, level=None):
	START='\033['
	FINISH='\033[0m'

	BOLD='1;'

	BLACK="30"
	RED="31"
	GREEN="32"
	YELLOW="33"
	BLUE="34"
	MAGENTA="35"
	CYAN="36"
	GREY="37"

	BGBLACK="40"
	BGRED="41"
	BGGREEN="42"
	BGYELLOW="43"
	BGBLUE="44"
	BGMAGENTA="45"
	BGCYAN="46"
	BGGREY="47"

	if level == "header" :
		COLOURS="%s;%s;%sm" % (BOLD, GREY, BGBLUE)
	if level == "error" :
		COLOURS="%s;%sm" % (GREY, BGRED)
	elif level == "warning" :
		COLOURS="%s;%sm" % (BLACK,BGYELLOW)
	elif level == "debug" :
		COLOURS="%sm" % YELLOW
	elif level == "result" :
		COLOURS="%sm" % CYAN
	elif level == "success" :
		COLOURS="%sm" % GREEN
	elif level == "choice" :
		COLOURS="%sm" % BLUE
	else :
		COLOURS="%sm" % GREY

	return "%s%s %s %s" % (START, COLOURS, message, FINISH)

