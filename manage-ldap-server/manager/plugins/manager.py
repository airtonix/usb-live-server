import os, sys, imp
import ConfigParser
from lib.messages import message
from lib.debug import debug


class PluginManager (object):

	def __init__(self,parent,path=None):
		debug( message("Plugin Manager Loading",'header') )
		self.MODULE_PATH = os.path.abspath(os.path.dirname(__file__))
		self.plugins = {}
		self.events = {}
		self.interfaces = {}
		self.parent = parent
		self.process_template = self.parent.process_template
		self.required_plugin_files = [ "manifest.conf", "plugin.py" ]
		self.plugin_dir = path
		self.load_plugins()
		debug( message("Plugin Manager Ready",'success') )

	def load_plugins(self):
		path = self.plugin_dir
		debug( message("Processing Plugins", "header"), " : ", message(path) )
		#sys.path.append(path)

		# for directory in os.path.listdirs(self.plupathgin_dir) :
		for item in os.listdir(path):
			folder_has_plugin_files = False
			folder = os.path.join(path, item)
			if os.path.isdir( folder ):
				debug( message("Inspecting : %s" % folder ) )
				files = os.listdir( folder )
				if len( set(self.required_plugin_files) & set(files) ) == len(self.required_plugin_files) :
					self.load_plugin( folder )
				else:
					debug( message("folder is not a valid plugin", "error"), name )

	def load_plugin(self, plugin_path):
		config_file = open( os.path.join(plugin_path, "manifest.conf") )
		name = os.path.split(plugin_path)[1]
		plugin_config = ConfigParser.RawConfigParser()
		debug( message("Reading plugin %s " % name ) )
		plugin_config.read(config_file)
		# do stuff.
#		__import__("plugins.%s.plugin" % name)
		__import__("plugins.%s.plugin" % name)
		plugin = sys.modules["plugins.%s.plugin" % name]

		self.plugins[name] = {
			"config" : plugin_config,
			"path" : plugin_path,
			"object" : plugin
		}
		if plugin.HasAttr("set_parent") :
			plugin.set_parent(self.parent)

		if plugin.hasattr("events") :
			for event in plugin["events"] :
				self.set_event_plugin(event, plugin_path)

		if plugin.hasattr("interfaces") :
			for interface in plugin["interfaces"] :
				self.set_interface_plugin(interface, plugin_path)

	def set_event_plugin(self, event, plugin):
		self.events[event].append(plugin)

	def set_interface_plugin(self, interface, plugin):
		self.interfaces[interface].append(plugin)

	def trigger_event(self, event, *args, **kwargs):
		""" Call this function to trigger an event. It will run any plugins that
				have registered themselves to the event. Any additional arguments or
				keyword arguments you pass in will be passed to the plugins.
		"""
		for plugin in events[event]:
			plugin(*args, **kwargs)

	def trigger_interface(self, interface, *args, **kwargs):
		""" Call this function to trigger an interface. It will run any plugins that
				have registered themselves to the interface. Any additional arguments or
				keyword arguments you pass in will be passed to the plugins.
		"""
		for plugin in interfaces[interface]:
			plugin(*args, **kwargs)


class PluginItem (object):

	def __init__(self):
		events = {}
		interfaces = {}
		preferences = {}

	def message(self,msg,level=None):
		return message(msg,level)

	def debug(self,*args):
		debug(args)

	def preferences(self):
		pass

	def event(self,event_name=None):
		pass

	def interface(self,view=None):
		pass

