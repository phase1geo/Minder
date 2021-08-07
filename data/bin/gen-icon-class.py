# Usage:  python gen-icon-class.py


import xml.etree.ElementTree as ET

tree = ET.parse('data/icons/flat-color-icons/index.html')
root = tree.getroot()

categories   = []
replacements = [
  ["_az", "_(A->Z)"],
  ["_za", "_(Z->A)"],
  ["_12", "_(1->2)"],
  ["_21", "_(2->1)"],
  ["_asc", "_ascending"],
  ["_desc", "_descending"],
  ["Sms", "SMS"],
  ["Mms", "MMS"],
  ["Iphone", "iPhone"],
  ["Ipad", "iPad"],
  ["Faq", "FAQ"],
  ["Ok", "OK"],
  ["Vip", "VIP"],
  ["Slr", "SLR"],
  ["_", " "]]

# Open the class file for writing
cfile = open("src/StickerSet.vala", "w")

cfile.write('/* This is a generated file.  Do not edit. */\n\n')
cfile.write('using Gee;\n\n')
cfile.write('public class StickerSet {\n\n')
cfile.write('  public class StickerInfo {\n')
cfile.write('    public string resource {set; get;}\n')
cfile.write('    public string tooltip  {set; get;}\n')
cfile.write('    public StickerInfo( string resource, string tooltip ) {\n')
cfile.write('      this.resource = resource;\n')
cfile.write('      this.tooltip  = tooltip;\n')
cfile.write('    }\n')
cfile.write('  }\n')
cfile.write('  Array<string>                      categories;\n')
cfile.write('  HashMap<string,Array<StickerInfo>> category_icons;\n\n')
cfile.write('  public StickerSet() {\n')
cfile.write('    categories     = new Array<string>();\n')
cfile.write('    category_icons = new HashMap<string,Array<StickerInfo>>();\n')

for h2 in root.iter('h2'):
    cfile.write('    categories.append_val( _( "' + h2.text + '" ) );\n')
    categories.append(h2.text)

index = 0
for p in root.iter('p'):
    category = categories.pop(0)
    variable = "array{}".format(index)
    cfile.write('    var ' + variable + ' = new Array<StickerInfo>();\n' )
    for img in p.iter('img'):
        resource = img.get('title').split(".")[0]
        title    = resource.capitalize()
        for str, replace in replacements:
           title = title.replace(str, replace)
        cfile.write('    ' + variable + '.append_val( new StickerInfo( "' + resource + '", _( "' + title + '" ) ) );\n')
    cfile.write('    category_icons.set( _( "' + category + '" ), ' + variable + ' );\n')
    index = index + 1

cfile.write('  }\n\n')
cfile.write('  public Array<string> get_categories() {\n')
cfile.write('    return( categories );\n')
cfile.write('  }\n\n')
cfile.write('  public Array<StickerInfo> get_category_icons( string category ) {\n')
cfile.write('    return( category_icons.get( category ) );\n')
cfile.write('  }\n')
cfile.write('  public string get_icon_tooltip( string resource ) {\n')
cfile.write('    for( int i=0; i<categories.length; i++ ) {\n')
cfile.write('      var icons = category_icons.get( categories.index( i ) );\n')
cfile.write('      for( int j=0; j<icons.length; j++ ) {\n')
cfile.write('        if( icons.index( j ).resource == resource ) {\n')
cfile.write('          return( icons.index( j ).tooltip );\n')
cfile.write('        }\n')
cfile.write('      }\n')
cfile.write('    }\n')
cfile.write('    return( "" );\n')
cfile.write('  }\n')
cfile.write('}\n')

cfile.close()


