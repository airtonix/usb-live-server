#!/usr/bin/env python
import pygtk; pygtk.require('2.0')
import gtk
from lib.messages import message
from lib.debug import debug
from plugins.manager import PluginItem

class PluginConfig (PluginItem):

	def __init__(self):
		self.events = {}
		self.interfaces = {}
		self.preferences = {}
		self.plugin_path = os.path.abspath(os.path.dirname(__file__))
		self.parent = None

	def set_parent(self,parent):
		self.parent = parent

	def preferences(self):
		pass

	def event(self,event_name=None):
		pass

	def interface(self,view=None):

		config = gtk.Builder()
		config.add_from_file( os.path.join( self.plugin_path, "config.glade" ) )

