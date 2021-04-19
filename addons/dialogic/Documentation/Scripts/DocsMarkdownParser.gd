extends Node

var heading1_font = "res://addons/dialogic/Documentation/Theme/DocumentationH1.tres"
var heading2_font = "res://addons/dialogic/Documentation/Theme/DocumentationH2.tres"
var heading3_font = "res://addons/dialogic/Documentation/Theme/DocumentationH3.tres"
var heading4_font = "res://addons/dialogic/Documentation/Theme/DocumentationH4.tres"
var heading5_font = "res://addons/dialogic/Documentation/Theme/DocumentationH5.tres"

## These will change with each parsing, but can be saved manually after parsing 
var heading1s = []
var heading2s = []
var heading3s = []
var heading4s = []
var heading5s = []
var result = ""
var bolded = []
var italics = []
var striked = []
var coded = []
var linknames = []
var links = []
var imagenames = []
var imagelinks = []
var lists = []
var underlined = []

################################################################################
##							PUBLIC FUNCTIONS 								  ##
################################################################################

### Takes a markdown string and returns it as BBCode
func parse(content : String):
	
	heading1s = []
	heading2s = []
	heading3s = []
	heading4s = []
	heading5s = []
	result = ""
	bolded = []
	italics = []
	striked = []
	coded = []
	linknames = []
	links = []
	imagenames = []
	imagelinks = []
	lists = []
	underlined = []

	var regex = RegEx.new()

	## Find all occurences of bold text
	regex.compile('\\*\\*(?<boldtext>.*)\\*\\*')
	result = regex.search_all(content)
	if result:
		for res in result:
			bolded.append(res.get_string("boldtext"))

	## Find all occurences of underlined text
	regex.compile('\\_\\_(?<underlinetext>.*)\\_\\_')
	result = regex.search_all(content)
	if result:
		for res in result:
			underlined.append(res.get_string("underlinetext"))

	## Find all occurences of italic text
	regex.compile("\\*(?<italictext>.*)\\*")
	result = regex.search_all(content)
	if result:
		for res in result:
			italics.append(res.get_string("italictext"))

	## Find all occurences of underlined text
	regex.compile("~~(?<strikedtext>.*)~~")
	result = regex.search_all(content)
	if result:
		for res in result:
			striked.append(res.get_string("strikedtext"))

	## Find all occurences of code snippets
	regex.compile("`(?<coded>.*)`")
	result = regex.search_all(content)
	if result:
		for res in result:
			coded.append(res.get_string("coded"))
#
#	This doesn't work right now. Just messes up everything.
#   Try to fix this sometime.
#	## Find all occurences of list items
#	regex.compile("[-+*](?<element>\\s.*)")
#	result = regex.search_all(content)
#	if result:
#		for res in result:
#			lists.append(res.get_string("element"))

	## Find all occurences of images
	regex.compile("!\\[(?<imgname>.*)\\]\\((?<imglink>.*)\\)")
	result = regex.search_all(content)
	if result:
		for res in result:
			if res.get_string("imglink")!="":
				imagelinks.append(res.get_string("imglink"))
			if res.get_string("imgname")!="":
				imagenames.append(res.get_string("imgname"))

	## Find all occurences of links (that are not images)
	regex.compile("[^!]\\[(?<linkname>.*?)\\]\\((?<link>[^\\)]*\\S*?)\\)")
	result = regex.search_all(content)
	if result:
		for res in result:
			if res.get_string("link")!="":
				links.append(res.get_string("link"))
			if res.get_string("linkname")!="":
				linknames.append(res.get_string("linkname"))
	
	## Find all heading1s
	regex.compile("(?:\\n|^)#(?<heading>[^#\\n]+)")
	result = regex.search_all(content)
	if result:
		for res in result:
			heading1s.append(res.get_string("heading"))
	
	## Find all heading2s
	regex.compile("(?:\\n|^)##(?<heading>[^#\\n]+)")
	result = regex.search_all(content)
	if result:
		for res in result:
			heading2s.append(res.get_string("heading"))
	
	## Find all heading3s
	regex.compile("(?:\\n|^)###(?<heading>[^#\\n]+)")
	result = regex.search_all(content)
	if result:
		for res in result:
			heading3s.append(res.get_string("heading"))
	
	## Find all heading4s
	regex.compile("(?:\\n|^)####(?<heading>[^#\\n]+)")
	result = regex.search_all(content)
	if result:
		for res in result:
			heading4s.append(res.get_string("heading"))
	
	## Find all heading5s
	regex.compile("(?:\\n|^)#####(?<heading>[^#\\n]+)")
	result = regex.search_all(content)
	if result:
		for res in result:
			heading5s.append(res.get_string("heading"))
	
	## Add in all the changes
	for bold in bolded:
		content = content.replace("**"+bold+"**","[b]"+bold+"[/b]")
	for italic in italics:
		content = content.replace("*"+italic+"*","[i]"+italic+"[/i]")
	for strik in striked:
		content = content.replace("~~"+strik+"~~","[s]"+strik+"[/s]")
	for underline in underlined:
		content = content.replace("__"+underline+"__","[u]"+underline+"[/u]")
	for code in coded:
		content = content.replace("`"+code+"`","[code]"+code+"[/code]")
	for i in links.size():
		content = content.replace("["+linknames[i]+"]("+links[i]+")","[url="+links[i]+"]"+linknames[i]+"[/url]")
	for i in imagenames.size():
		var imagelink_to_use = imagelinks[i]
		if imagelink_to_use.begins_with("http"):
			var path_parts = imagelink_to_use.split("/Documentation/")
			if path_parts.size() > 1:
				imagelink_to_use = DocsHelper.documentation_path +"/"+ path_parts[1]
			else:
				imagelink_to_use = "icon.png"
		content = content.replace("!["+imagenames[i]+"]("+imagelinks[i]+")","[img=700]"+imagelink_to_use+"[/img]")
	for heading1 in heading1s:
		content = content.replace("#"+heading1, "[font="+heading1_font+"]"+heading1.strip_edges()+"[/font]")
	for heading2 in heading2s:
		content = content.replace("##"+heading2, "[font="+heading2_font+"]"+heading2.strip_edges()+"[/font]")
	for heading3 in heading3s:
		content = content.replace("###"+heading3, "[font="+heading3_font+"]"+heading3.strip_edges()+"[/font]")
	for heading4 in heading4s:
		content = content.replace("####"+heading4, "[font="+heading4_font+"]"+heading4.strip_edges()+"[/font]")
	for heading5 in heading5s:
		content = content.replace("#####"+heading5, "[font="+heading5_font+"]"+heading5.strip_edges()+"[/font]")
	for element in lists:
		if content.find("- "+element):
			content = content.replace("-"+element,"[indent]-"+element+"[/indent]")
		if content.find("+ "+element):
			content = content.replace("+"+element,"[indent]-"+element+"[/indent]")
		if content.find("* "+element):
			content = content.replace("+"+element,"[indent]-"+element+"[/indent]")
	
	return content
