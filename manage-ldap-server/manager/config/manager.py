#!/usr/bin/env python
import sys, subprocess, re, os
import ConfigParser
import string

import pygtk; pygtk.require('2.0')
import gtk
from lib.messages import message
from lib.debug import debug

class PreferencesManager (object):

	def __init__(self,parent=None, path = None):
		self.parent = parent
		self.USER_HOME = os.path.abspath(os.getenv("HOME"))
		self.USERNAME = os.path.abspath(os.getenv("USER"))
		self.MODULE_PATH = os.path.abspath(os.path.dirname(__file__))
		if path != None :
			self.CONFIG_PATH = path
		else :
			msg = "Can't continue without a configuration file. Please provide a path to a valid ini based configuration file."
			debug( message(msg,"error") )
			raise BaseException, msg

		self.APP_PATH = os.path.abspath(os.path.dirname(__file__))
		self.APP_NAME = parent.APP_NAME

		self.process_template = self.parent.process_template
		self.data = None
		self.config = ConfigParser.RawConfigParser()

		self.DEFAULT_CONFIG="""[main]
default-profile=default

[profile-default]
entry_admin_dn=cn=admin, dc=domain, dc=domain
entry_admin_password=password
entry_server_dn=dc=hostname, dc=domain
entry_server_fqdn=subdomain.hostname.domain
	"""
		self.SELECTED_PROFILE_NAME = None
		self.SELECTED_PROFILE = None
		self.DEFAULT_PROFILE_NAME = "default"

		self.read_config_file(self.config,self.CONFIG_PATH )

		self.set_default_profile_name( self.config.get("main",'default-profile') )
		self.set_current_profile_name( self.get_default_profile_name() )
		self.set_current_profile()


#########################
# CONFIG FUNCTIONS
	def save_config_file (self,config_obj=None, path=None):
		""" Function doc """
		if config_obj == None :
			return None

		with open(self.ensure_file(path), 'wb') as configfile:
			config_obj.write(configfile)

	def read_config_file  (self, config_obj=None, path=None):
		""" Function doc """
		if path == None:
			raise BaseException, "To load a config file, we need a path."
		if config_obj == None :
			config_obj = ConfigParser.RawConfigParser()

		file = self.ensure_file(path,self.DEFAULT_CONFIG)
		config_obj.read(file)
		return config_obj
	"""
		PROFILES
	"""

	def get_current_profile (self):
		profile = self.SELECTED_PROFILE
		profile_name = self.get_current_profile_name()
		debug( message("Retrieving Profile","header"), profile_name )
		debug( message(" %s has %s elements" % (profile_name, len( profile.keys() )) ) )
		return profile

	def set_current_profile (self,data=None):
		""" Function doc """
		if(data == None):
			data = self.load_profile(self.SELECTED_PROFILE_NAME)
		self.SELECTED_PROFILE = data

	def get_current_profile_name (self):
		return self.SELECTED_PROFILE_NAME
	def set_current_profile_name (self,name):
		""" Function doc """
		self.SELECTED_PROFILE_NAME = name

	def get_default_profile_name (self):
		return self.DEFAULT_PROFILE_NAME
	def set_default_profile_name (self,name):
		debug( message("Storing Default Profile","header"),name)
		self.DEFAULT_PROFILE_NAME = name
		self.config.set("main", 'default-profile', name )
		self.save_config_file(self.config,self.CONFIG_PATH)

	def get_expanded_profile_name (self,name):
		""" Function doc """
		return "profile-%s" % name

	def save_profile (self, name, data, is_default=False):
		""" Function doc """
		if not name:
			raise BaseException, "Profile Name Required"
		if not data:
			raise BaseException, "Profile Data Required"

		profile_name = self.get_expanded_profile_name(name)

		if(not profile_name in self.config.sections()) :
			self.config.add_section(profile_name)

		for key,item in data.items() :
			self.config.set(profile_name, key, item)

		if is_default :
			self.config.set("main", 'default-profile', name )

		self.save_config_file(self.config,self.CONFIG_PATH)

	def load_profile (self,name):
		""" Function doc """
		if not name:
			raise BaseException, "Profile Name Required"

		profile_name = self.get_expanded_profile_name(name)

		debug( message("Loading setttings"), name)

		self.set_current_profile(name)
		output = {}
		for item in self.config.options(profile_name):
			output[item] = self.config.get(profile_name, item)
		return output

#########################
# FILE FUNCTIONS
	def ensure_dir(self, path) :
		"""
			Looks for a folder at provided path, creates it if it does not exist.
			Returns the folder.
		"""
		folder = os.path.exists(path)
		if not folder:
			debug( message("Folder [ %s ] does not exist, creating it." % path,"warning") )
			folder = os.makedirs(path)
		return folder

	def ensure_file (self, path, default_content=None):
		"""
			Looks for  file at provided path,
			creates it if it does not exist,
			files it with default content if provided
			Returns the file.
		"""
		path = self.process_template(path) #expand template vars

		if not os.path.exists(path) :
			debug( message("File [ %s ] does not exist, creating it." % path,"warning") )
			self.ensure_dir(os.path.dirname(path))
			file = open(path, 'w')
			if default_content != None:
				file.write(default_content)
			file.close()
			file = path
		else :
			debug( message("file is available\n\t>%s" % path) )
			file = path

		return file



#################################
#
#
#
#
#

class PreferencesManagerInterface(object):
	parent = None

	def __init__(self,parent=None,config_manager=None):
		"""
			Load the glade file,
			begin rendering interface.
		"""
		self.interface_ready = False
		self.parent=parent
		if not config_manager:
			raise BaseException, "No PreferencesManager Provided"
		self.config_manager=config_manager

		self.MODULE_PATH = os.path.dirname(__file__)
		self.filename = os.path.splitext(__file__)[0]
		self.required_plugins = ["server", "plugins"]

		self.builder = gtk.Builder()
		self.builder.add_from_file( os.path.join(self.MODULE_PATH, "%s.glade" % self.filename) );
		self.builder.connect_signals(self)

		self.render_interface()
		if self.interface_ready :
			self.list_profiles()
		# Load the Current Profile Data into the Preferences Interface Elements.
			self.load_data( self.config_manager.get_current_profile() )

	def list_profiles (self):
		""" Function doc """
		if not self.config_manager.config == None:
			comboboxentry = self.profile_combo
			liststore_profiles = gtk.ListStore(str)
			comboboxentry.set_model(liststore_profiles)
			default_profile_index = 0
			default_profile_name = self.config_manager.get_default_profile_name()
			count = 0

			for profile in self.config_manager.config.sections() :
				if (profile == "main") :
					continue
				name = re.search("profile-(.*)",profile)
				if( name == default_profile_name) :
					default_profile_index = count

				liststore_profiles.append([name.group(1)])
				count += 1

			comboboxentry.set_text_column(0)
			comboboxentry.set_active(default_profile_index)

	def save_data(self):
		""""""
		output = {}
		for element in self.data_elements:
			obj = self.builder.get_object(element)
			output[element] = obj.get_text()
		self.config_manager.save_profile( self.profile_combo.get_active_text(), output, self.profile_default_toggle.get_active() )

	def load_data(self,data=None):
		"""
			Load config data from file
		"""
		print(data)
		if data == None :
			""""""
			raise BaseException, "Can't retrieve config"

		for element in self.data_elements:
			obj = self.builder.get_object(element)
			obj.set_text( data[element] )


	def debug(self,msg):
		target = self.statusbar
		if self.parent :
			target = self.parent.statusbar
		target.push



	def render_interface(self):
		self.window = self.builder.get_object('window_main')
		self.notebook = self.builder.get_object('notebook')
		plugin_builder = gtk.Builder()
		for name,data in self.parent.plugins.plugins.items() :
			plugin_config_path = os.path.join(data["path"],"config.glade")
			# check for and load the interface.glade
			if os.path.isfile( plugin_config_path ):
				debug( message("Loading Config Plugin : "), name )
				plugin_builder.add_from_file( plugin_config_path );

				Tab = gtk.Label()
				Tab.set_text(name)

				Page = gtk.HBox()
				Page.pack_start( plugin_builder.get_object("plugin") )

				self.notebook.append_page(Page, Tab)
				# read our profile and check for "plugin-<pluginname>" section

				#		self.profile_combo = self.builder.get_object("comboboxentry_profiles")
				#		self.profile_default_toggle = self.builder.get_object("checkbutton_setDefault")

	def show(self,widget=None, data=None):
		self.window.show_all()
	def hide(self,widget=None, data=None):
		self.window.hide_all()
	def quit(self):
		self.window.destroy()

	#####################
	# EVENTS
	def on_button_apply_clicked(self,widget=None, data=None):
		self.save_data()
	def on_button_cancel_clicked(self,widget=None, data=None):
		self.quit()
	def on_button_ok_clicked(self,widget=None, data=None):
		#save data
		self.save_data()
		#close window
		self.quit()

	def on_comboboxentry_profiles_changed(self,widget=None, data=None):
		pass
	def on_comboboxentry_profiles_popdown(self,widget=None, data=None):
		pass
	def on_comboboxentry_profiles_popup(self,widget=None, data=None):
		pass
	def on_comboboxentry_profiles_editing_done(self,widget=None, data=None):
		pass
	def on_comboboxentry_profiles_child_added(self,widget=None, data=None):
		pass
	def on_comboboxentry_profiles_child_removed(self,widget=None, data=None):
		pass

	def on_checkbutton_setDefault_toggled(self,widget=None, data=None):
		pass
	def on_window_main_destroy(self,widget=None,data=None):
		""""""

if __name__ == "__main__":
	app_window = PreferencesManagerInterface()
	app_window.quit = (lambda x=None : gtk.main_quit())
	app_window.show()
	gtk.main()

