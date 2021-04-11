import std.algorithm;
import std.file;
import std.json;
import std.path: expandTilde;
import std.stdio;
import std.string;

enum string help = import("help.txt");
enum string templateHelp = import("template.txt");

Template[] activeTemplates;

string defaultNamespace = "minecraft";
string outputLocation = "src/main/resources/";

string home;

void main(string[] args) {
	args = args[1..$];

	home = expandTilde("~/.mcgen/");

	mkdirRecurse(home ~ "templates/");

	string[] flags, objects;
	string type = args[0].toLower;
	for (int i = 1; i < args.length; i++) {
		if (!args[i].startsWith("--")) {
			flags = args[1..i];
			objects = args[i..$];
			break;
		}
	}
	if (flags.length == 0 && objects.length == 0) {
		flags = args[1..$];
	}

	foreach (string flag; flags) {
		if (flag == "--verbose") {
			continue;
		}
		string[] parts = flag.split('=');
		if (parts.length != 2) {
			writeln("Invalid flag '%s'".format(flag));
			return;
		}
		if (parts[0] == "--namespace") {
			defaultNamespace = parts[1];
		} else if (parts[0] == "--location") {
			outputLocation = parts[1];
			if (!outputLocation.endsWith('/')) {
				outputLocation ~= '/';
			}
		} else if (parts[0] == "--template") {
			activeTemplates ~= Template(home ~ "templates/" ~ parts[1]);
		} else {
			writeln("Invalid flag '%s'".format(flag));
			return;
		}
	}

	if (type == "help" || type == "--help") {
		writeln(help);
		return;
	} else if (type == "template" || type == "templates") {
		writeln(templateHelp);
		writeln("Available Templates:");
		string dir = home ~ "templates/";
		bool verbose = flags.canFind("--verbose");
		foreach (string file; dirEntries(dir, SpanMode.shallow)) {
			if (isDir(file)) {
				Template temp = Template(file);
				writeln("\t%s".format(file[dir.length..$]));
				if (verbose) {
					writeln("\t  [%s] Item Model".format(temp.itemModel ? "✓" : " "));
					writeln("\t  [%s] Block State".format(temp.blockState ? "✓" : " "));
					writeln("\t  [%s] Block Model".format(temp.blockModel ? "✓" : " "));
					writeln("\t  [%s] Block Item Model".format(temp.blockItemModel ? "✓" : " "));
					writeln("\t  [%s] Block Loot Table".format(temp.blockLootTable ? "✓" : " "));
				} else {
					if (temp.empty) {
						writeln("\t  [Empty]");
					} else {
						if (temp.itemModel) {
							writeln("\t  -Item Model");
						}
						if (temp.blockState) {
							writeln("\t  -Block State");
						}
						if (temp.blockModel) {
							writeln("\t  -Block Model");
						}
						if (temp.blockItemModel) {
							writeln("\t  -Block Item Model");
						}
						if (temp.blockLootTable) {
							writeln("\t  -Block Loot Table");
						}
					}
				}
			}
		}
		return;
	}

	if (defaultNamespace == "minecraft") {
		getDefaultNamespace();
	}

	CompiledTemplate comp = CompiledTemplate(activeTemplates);

	if (type == "item") {
		if (objects.length < 1) {
			writeln("Not enough args");
			return;
		}
		foreach (string s; objects) {
			Identifier id = Identifier(s);

			string path = outputLocation ~ "assets/" ~ id.namespace ~ "/models/item/";
			mkdirRecurse(path);
			File f = File(path ~ id.path ~ ".json", "w");
			f.write(comp.itemModel.replace("%NAMESPACE", id.namespace).replace("%PATH", id.path));
			f.close();

			writeln("[mcgen] Created item files for " ~ id.getName());
		}
	} else if (type == "block") {
		if (objects.length < 1) {
			writeln("Not enough args");
			return;
		}
		foreach (string s; objects) {
			Identifier id = Identifier(s);

			string path = outputLocation ~ "assets/" ~ id.namespace ~ "/models/block/";
			mkdirRecurse(path);
			File f = File(path ~ id.path ~ ".json", "w");
			f.write(comp.blockModel.replace("%NAMESPACE", id.namespace).replace("%PATH", id.path));
			f.close();

			path = outputLocation ~ "assets/" ~ id.namespace ~ "/blockstates/";
			mkdirRecurse(path);
			f = File(path ~ id.path ~ ".json", "w");
			f.write(comp.blockState.replace("%NAMESPACE", id.namespace).replace("%PATH", id.path));
			f.close();

			path = outputLocation ~ "data/" ~ id.namespace ~ "/loot_tables/blocks/";
			mkdirRecurse(path);
			f = File(path ~ id.path ~ ".json", "w");
			f.write(comp.blockLootTable.replace("%NAMESPACE", id.namespace).replace("%PATH", id.path));
			f.close();

			path = outputLocation ~ "assets/" ~ id.namespace ~ "/models/item/";
			mkdirRecurse(path);
			f = File(path ~ id.path ~ ".json", "w");
			f.write(comp.blockItemModel.replace("%NAMESPACE", id.namespace).replace("%PATH", id.path));
			f.close();

			writeln("[mcgen] Created block files for " ~ id.getName());
		}
	}
}

void getDefaultNamespace() {
	string path = "src/main/resources/fabric.mod.json";
	if (exists(path)) {
		string text = cast(string) read(path);
		JSONValue j = parseJSON(text);
		defaultNamespace = j["id"].get!string;
		writeln("[mcgen] fabric.mod.json found, using namespace \"", defaultNamespace ,"\"");
	} else {
		writeln("[mcgen] fabric.mod.json not found, using default namespace \"minecraft\"");
	}
}

struct Identifier {
	string namespace;
	string path;

	this(string combined) {
		string[] strings = combined.split(":");
		if (strings.length == 1) {
			namespace = defaultNamespace;
			path = combined;
		} else {
			namespace = strings[0];
			path = strings[1];
		}
	}

	string getName() {
		return namespace ~ ":" ~ path;
	}
}

struct Template {
	string path;
	bool itemModel;
	bool blockState, blockModel, blockItemModel, blockLootTable;

	bool empty = true;

	this(string path) {
		this.path = path;
		string[] entries;
		foreach (string part; dirEntries(path, SpanMode.shallow)) {
			string local = part[path.length..$];
			if (local == "/item_model.json") {
				itemModel = true;
			} else if (local == "/block_state.json") {
				blockState = true;
			} else if (local == "/block_model.json") {
				blockModel = true;
			} else if (local == "/block_item_model.json") {
				blockItemModel = true;
			} else if (local == "/block_loot_table.json") {
				blockLootTable = true;
			} else {
				continue;
			}
			empty = false;
		}
	}
}

struct CompiledTemplate {
	string itemModel;
	string blockState, blockModel, blockItemModel, blockLootTable;

	this(Template[] templates) {
		foreach (Template temp; templates) {
			if (temp.itemModel) {
				itemModel = cast(string) read(temp.path ~ "/item_model.json");
				break;
			}
		}
		foreach (Template temp; templates) {
			if (temp.blockState) {
				blockState = cast(string) read(temp.path ~ "/block_state.json");
				break;
			}
		}
		foreach (Template temp; templates) {
			if (temp.blockModel) {
				blockModel = cast(string) read(temp.path ~ "/block_model.json");
				break;
			}
		}
		foreach (Template temp; templates) {
			if (temp.blockItemModel) {
				blockItemModel = cast(string) read(temp.path ~ "/block_item_model.json");
				break;
			}
		}
		foreach (Template temp; templates) {
			if (temp.blockLootTable) {
				blockLootTable = cast(string) read(temp.path ~ "/block_loot_table.json");
				break;
			}
		}
		if (itemModel.length == 0) {
			itemModel = import("item_model.json");
		}
		if (blockState.length == 0) {
			blockState = import("block_state.json");
		}
		if (blockModel.length == 0) {
			blockModel = import("block_model.json");
		}
		if (blockItemModel.length == 0) {
			blockItemModel = import("block_item_model.json");
		}
		if (blockLootTable.length == 0) {
			blockLootTable = import("block_loot_table.json");
		}
	}
}