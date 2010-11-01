#!/usr/bin/env python
import pygtk; pygtk.require('2.0')
import gtk
from lib.messages import message
from lib.debug import debug

class PluginItem (object):

	def __init__(self):
		events = {}
		interfaces = {}
		preferences = {}

	def preferences(self):
		pass

	def event(self,event_name=None):
		pass

	def interface(self,view=None):
		pass

