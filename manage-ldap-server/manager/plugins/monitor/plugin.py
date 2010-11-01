#!/usr/bin/env python
import sys, subprocess, re, string
import ConfigParser
import pygtk; pygtk.require('2.0')
import gtk
import ldap
import os, inspect
from plugins.manager import PluginItem

class LogViewMonitor (PluginItem):

	def __init__(self):
		""" """
		self.module_path = os.path.dirname(__file__)
		self.filename = os.path.splitext(__file__)[0]
		self.PLUGIN_NAME = "Monitor"
		self.PLUGIN_AUTHOR = "Zenobius Jiricek"
		self.CONFIG_FILE = "monitor.conf"
		self.builder = gtk.Builder()
		self.builder.add_from_file( os.path.join(self.module_path, "%s.glade" % self.filename) );

		self.column_schema = (["id", "integer"], ["name","string"], ["source","string"], ["target","string"], ["user","string"])
		self.statusbar_items_count = 1

		self.render_interface()
		self.show()

	def interface(self):
		self.panel = self.builder.get_object('plugin_interface')
		self.window.connect("delete_event", self.quit)
		self.window.connect("destroy", self.quit)
		self.builder.connect_signals(self)
		self.statusbar = self.builder.get_object('statusbar')
		self.statusbar_context_id = self.statusbar.get_context_id("Statusbar example")

		self.menubar = self.builder.get_object('menubar')
		self.menubar = self.builder.get_object('toolbar')

		self.views = self.builder.get_object("notebook_events")
		self.new_view("All", None, {"server": "ldap.edge.local", "user" : "admin", "credentials" : ""})

	def show(self,widget=None, data=None):
		self.window.show_all()


	#####################
	# Statusbar Functions
	def statusbar_push_item(self, widget, data):
		buff = "%s" % data
		self.statusbar_items_count = self.statusbar_items_count + 1
		self.statusbar.push(self.statusbar_context_id, buff)
		return

	def statusbar_pop_item(self, widget, data):
		self.statusbar.pop(data)
		return

	#####################
	# View Data

	def new_view(self,view_name,filters=None, credentials=None):
		Tab = gtk.Label()
		Tab.set_text(view_name)
		Tab.connect("populate-popup", self.render_view_page_contextmenu)

		Page = gtk.Alignment(0, 0, 1, 1)
		Page.Data = []
		Page.TreeStore = self.create_liststore_model(self.column_schema)
		Page.TreeView = gtk.TreeView(Page.TreeStore)
		Page.TreeView.set_rules_hint(True)
		Page.TreeView.connect("row-activated", self.on_treeview_row_activated)
		self.create_liststore_view(Page.TreeView, self.column_schema)

		ScrolledWindow = gtk.ScrolledWindow()
		ScrolledWindow.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
		Page.add(ScrolledWindow)
		ScrolledWindow.add(Page.TreeView)

		self.views.append_page(Page, Tab)

	def update_view(self,treeview,data):
		"""
			data = {
				id : integer
				name : string,
				source : string,
				target : string,
				user : string
			}
		"""
		row_id = 0
		for row in data:
			treeview.append([ data["id"], data["name"], data["source"], data["target"], data["user"] ])

	def render_view_page_contextmenu(self, widget=None, data=None):
		""" """

	def create_liststore_model(self, column_schema):
		model_columns = []
		for col in column_schema :
			if col[1] == "boolean" :
				model_columns.append(bool)
			if col[1] == "integer" :
				model_columns.append(int)
			if col[1] == "string" :
				model_columns.append(str)
			if col[1] == "pixbuff" :
				model_columns.append(gtk.gdk.Pixbuf)
		return gtk.ListStore(*model_columns)

	def create_liststore_view(self, treeview, column_schema):
		col_id = 0
		for col in column_schema :
			if col[1] == "boolean" :
				view_col = gtk.TreeViewColumn(col[0], gtk.CellRendererToggle(), text=col_id)
			if col[1] == "integer" :
				view_col = gtk.TreeViewColumn(col[0], gtk.CellRendererText(), text=col_id)
			if col[1] == "string" :
				view_col = gtk.TreeViewColumn(col[0], gtk.CellRendererText(), text=col_id)
			if col[1] == "pixbuff" :
				view_col = gtk.TreeViewColumn(col[0], gtk.CellRendererPixbuf(), text=col_id)

			view_col.set_sort_column_id(col_id)
			treeview.append_column(view_col)
			col_id +=1

	def get_view_data(self, view):
		pass

	######################
	# System Functions
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
	def on_imagemenuitem_edit_preferences_activate(self,widget=None,data=None):
		self.statusbar_push_item(widget,"Edit Preferences")
		self.render_preferences_interface()

	# Toolbar Items
	def on_toolbutton_filter_new_clicked(self, widget=None, data=None):
		self.statusbar_push_item(widget,"New Filter")

	def on_toolbutton_filter_save_clicked(self, widget=None, data=None):
		self.statusbar_push_item(widget,"Save Filter")

	def on_toolbutton_filter_saveas_clicked(self, widget=None, data=None):
		self.statusbar_push_item(widget,"Save Filter As...")

	def on_toolbar_preferences_clicked(self, widget=None, data=None):
		self.statusbar_push_item(widget,"Edit Preferences")
		self.render_preferences_interface()

	def on_toolbutton_events_reload_clicked(self, widget=None, data=None):
		self.statusbar_push_item(widget,"Reload Events")

	def on_toolbutton_events_clear_clicked(self, widget=None, data=None):
		self.statusbar_push_item(widget,"Clear Events")

	# Generic TreeStore Events
	def on_treeview_row_activated(self, widget=None, data=None):
		self.statusbar_push_item(widget,"Treeview %s : Row [%s] Activated" % (widget, data) )

	# Generic ListStore Events
	def on_liststore_view_notify(self,widget=None,data=None):
		self.statusbar_push_item(widget,"Liststore view : Notify [%s]"%data)

	def on_liststore_view_sort_column_changed(self,widget=None,data=None):
		self.statusbar_push_item(widget,"Liststore view : Column Changed [%s]"%data)

	def on_liststore_view_rows_reordered(self,widget=None,data=None):
		self.statusbar_push_item(widget,"Liststore view : Rows Reordered [%s]"%data)

	def on_liststore_view_row_inserted(self,widget=None,data=None):
		self.statusbar_push_item(widget,"Liststore view : Rows Inserted [%s]"%data)

	def on_liststore_view_row_has_child_toggled(self,widget=None,data=None):
		self.statusbar_push_item(widget,"Liststore view : Child Was Toggled [%s]"%data)

	def on_liststore_view_row_deleted(self,widget=None,data=None):
		self.statusbar_push_item(widget,"Liststore view : Row Deleted [%s]"%data)

	def on_liststore_view_row_changed(self,widget=None,data=None):
		self.statusbar_push_item(widget,"Liststore view : Row Changed [%s]"%data)

