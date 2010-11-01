#!/usr/bin/env python
import sys, subprocess, re, string
import ConfigParser
import pygtk; pygtk.require('2.0')
import gtk
import ldap
import os, inspect
#
import config.manager as preferences
import plugins.manager as plugins
from lib.messages import message
from lib.debug import debug

class LdapManager (object):

	def __init__(self):
		""" """
		self.MODULE_PATH = os.path.abspath(os.path.dirname(__file__))
		self.filename = os.path.splitext(__file__)[0]
		self.APP_NAME = "LdapManager"
		self.APP_AUTHOR = "Zenobius Jiricek"
		self.APP_DESC_SHORT = """ Pluggable LDAP Manager Interface"""
		self.APP_LOGO_NAME = "preferences-desktop-theme"
		self.APP_LOGO_SIZE = 64
		self.CONFIG_FILE = "main.conf"

		self.CONFIG_PATH_TEMPLATE = '${MODULE_PATH}/config/${CONFIG_FILE}'
		self.CONFIG_PATH = self.process_template(self.CONFIG_PATH_TEMPLATE)

		self.PLUGIN_PATH_TEMPLATE = '${MODULE_PATH}/plugins'
		self.PLUGIN_PATH = self.process_template(self.PLUGIN_PATH_TEMPLATE)

		self.builder = gtk.Builder()
		self.builder.add_from_file( os.path.join(self.MODULE_PATH, "%s.glade" % self.filename) );

		self.preferences = preferences.PreferencesManager(self, self.CONFIG_PATH)

		self.plugins = plugins.PluginManager(self, self.PLUGIN_PATH)

		self.render_interface()
		self.show()

	def render_interface(self):
		self.window = self.builder.get_object('window_main')
		self.window.connect("delete_event", self.quit)
		self.window.connect("destroy", self.quit)
		self.window.set_icon_name(self.APP_LOGO_NAME)

		self.builder.connect_signals(self)

		self.statusbar = self.builder.get_object('statusbar_main')
		self.statusbar_context_id = self.statusbar.get_context_id("Statusbar example")

		self.menubar = self.builder.get_object('menubar')
		self.menubar = self.builder.get_object('toolbar')

		self.pane = self.builder.get_object("hpane_main")

		self.aboutdialog = gtk.AboutDialog()


	def show(self,widget=None, data=None):
		self.window.show_all()

#########################
# AUX FUNCTIONS
	def process_template (self, str):
		""" Function doc """
		if re.search('\$\{([a-zA-Z_]+)\}', str)!=None :
			debug( message("processing : %s" % str) )
			template = string.Template(str)
			output = template.substitute(self.__dict__)
			return output
		else :
			debug( message("not a template string","warning") )
			return str

	#####################
	## Statusbar Functions
	def statusbar_push_item(self, widget, data):
		buff = "%s" % data
		self.statusbar_items_count = self.statusbar_items_count + 1
		self.statusbar.push(self.statusbar_context_id, buff)
		return

	def statusbar_pop_item(self, widget, data):
		self.statusbar.pop(data)
		return

	#####################
	## AboutDialog Functions
	def show_about_window(self):
		self.aboutdialog.set_version('0.0.1')
		self.aboutdialog.set_name(self.APP_NAME)
		self.aboutdialog.set_logo_icon_name(self.APP_LOGO_NAME)
		response = self.aboutdialog.run()
		self.aboutdialog.hide()

	#####################
	## Statusbar Functions
	def show_preferences_window(self):
		"""
			Render preferences window
		"""
		self.preferences_interface = preferences.PreferencesManagerInterface(self, self.preferences)
		self.preferences_interface.show()

	#####################
	# View Data



	######################
	## System Functions
	def quit(self,widget=None, data=None):
		"""
			Ends the GTK GLIB loop
		"""
		gtk.main_quit()

	def main(self):
		"""
			Starts the GTK GLIB loop
		"""
		gtk.main()


	###############
	## CALLBACKS

	# Menu Items

	# Actions
	def on_action_about_activate(self,data=None):
		self.show_about_window()

	def on_action_preferences_activate(self,data=None):
		self.show_preferences_window()

###############
# BOOT STRAP
###############
if __name__ == "__main__":
	app_window = LdapManager()
	app_window.main()
###############
###############

