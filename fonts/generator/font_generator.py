def showExceptionAndExit(exc_type, exc_value, tb):
    import traceback
    traceback.print_exception(exc_type, exc_value, tb)
    input("Press key to exit.")
    sys.exit(-1)


# nunito_sans default stroke width = 1.75


from PIL import Image, ImageDraw, ImageFont
from fontTools.ttLib import TTFont
import xml.etree.ElementTree as ET
import xml.dom.minidom as minidom
import sys
import os
import subprocess
import re
import math
import decimal_converter

sys.excepthook = showExceptionAndExit

IMAGE_WIDTH = 8192
IMAGE_HEIGHT = 256
CELL_WIDTH = 128
CELL_HEIGHT = 128
BOLD_STROKE_WIDTH = 1.5
STROKE_WIDTHS = [0, 1.5]


def convertToItalic(char, font, strokeWidth, char_width, char_height):
    temp_image = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
    temp_draw = ImageDraw.Draw(temp_image)
    temp_draw.text((64, 64), char, font=font, fill=(255, 255, 255, 255), stroke_width=strokeWidth, anchor="mm")

    temp_image = temp_image.transform((128, 128), Image.AFFINE, (1, 0.3, 0, 0, 1, 0), resample=Image.BICUBIC)

    lowestX, highestX = findFirstAndLastWhitePixel(temp_image, 0, 0)

    return temp_image, lowestX, highestX - lowestX


def findFirstAndLastWhitePixel(image, startX, startY):
    xCoordinates = []
    width, height = image.size
    
    for y in range(startY, startY + CELL_HEIGHT > height and height or (startY + CELL_HEIGHT)):
        for x in range(startX, startX + CELL_WIDTH > width and width or (startX + CELL_WIDTH)):
            r, g, b, a = image.getpixel((x, y))
            if r > 0 and g > 0 and b > 0 and a > 0:
                xCoordinates.append(x)

    if len(xCoordinates) == 0:
        return 0, 0

    xCoordinates.sort()
    return xCoordinates[0], xCoordinates[len(xCoordinates) - 1]


def getIsCharacterSupported(cmap, char):
    try:
        return cmap[ord(char)] != None
    except Exception as e:
        return False


def createFontImage(filename, characters, varType, bgColour, textColour, text, font, strokeWidth=0, fixedWidth=False, isItalic=False, isAlpha=False, strokeWidthKey=0):

    fixedWidth = fixedWidth or isItalic

    imageHeight = IMAGE_HEIGHT

    if fixedWidth:
        imageHeight *= 2

    buildCharacterDb = characters == None
    characters = characters or {}

    try:
        image = Image.new('RGBA', (IMAGE_WIDTH, imageHeight), bgColour)
        draw = ImageDraw.Draw(image)
        
        current_x = 0
        row = 0
        max_rows = imageHeight // CELL_HEIGHT

        for char in text:

            left, top, right, bottom = font.getbbox(char)

            char_width = (right - left)
            char_height = bottom - top

            
            
            if current_x + (fixedWidth and CELL_WIDTH or char_width) > IMAGE_WIDTH:
                row += 1
                current_x = 0
                if row >= max_rows:
                    print(f"Warning: Not enough vertical space for all characters.")
                    break
            
            y_pos = row * CELL_HEIGHT

            italicXOffset, italicWidth = 0, 0
            
            if isItalic:
                italic_image, italicXOffset, italicWidth = convertToItalic(char, font, strokeWidth, char_width, char_height)
                image.paste(italic_image, (current_x, y_pos), italic_image)
            else:
                draw.text((current_x + (fixedWidth and (CELL_WIDTH / 2) or 5), y_pos + CELL_HEIGHT / 2), char, font=font, fill=textColour, anchor = (fixedWidth and "mm" or "lm"), stroke_width=strokeWidth)

            byte = ord(char)

            if buildCharacterDb:

                characters[byte] = {
                    "character": char,
                    "byte": byte,
                    varType: {
                        str(strokeWidthKey): {
                            "width": isItalic and italicWidth or char_width,
                            "x": current_x + (isItalic and italicXOffset or (fixedWidth and 0) or 5),
                            "y": y_pos
                        }
                    }
                }

            elif isAlpha:

                leftX, rightX = findFirstAndLastWhitePixel(image, current_x, y_pos)

                characters[byte][varType]["0"]["left"] = (leftX - current_x) / 2
                characters[byte][varType]["0"]["right"] = (rightX - current_x) / 2
                
            else:

                if characters[byte].get(varType) == None:
                    characters[byte][varType] = {}

                characters[byte][varType][str(strokeWidthKey)] = {
                    "width": isItalic and italicWidth or char_width,
                    "x": current_x + (isItalic and italicXOffset or (fixedWidth and 0) or 5),
                    "y": y_pos
                }
                

            # 5px padding to char_width to prevent hooked characters appearing under adjacent characters
            current_x += fixedWidth and CELL_WIDTH or (char_width + strokeWidth * 2 + 10)

            
        image.save(filename + '.png', 'PNG')
        convertToDDS(f"{filename}.png", f"{filename}.dds")

        return characters

    except Exception as e:
        input(f"Error: {str(e)}")
        sys.exit(1)


def convertToDDS(inputPath, outputPath):
    try:
        cmd = ["textureTool/textureTool.exe", inputPath]
        result = subprocess.run(cmd, capture_output=False, text=True, check=True)
        print(f"Image successfully converted to DDS: {outputPath}")
        try:
            os.remove(inputPath)
        except Exception as e:
            print(f"Error deleting original PNG file: {e}")
            
    except subprocess.CalledProcessError as e:
        print(f"Error converting to DDS using batch file: {e.stderr}")
    except Exception as e:
        print(f"Unexpected error during conversion: {e}")


if len(sys.argv) == 0 or not os.path.isfile(sys.argv[1]):
    print("No input file provided")
    sys.exit()



font_path = sys.argv[1]
print("Font ID does not have to be unique; FontLibrary will make it unique and return the unique id")
font_name = input("Enter the id of the font (eg: GENERIC): ")
font_language = input("Enter the language of the font (latin, cyrillic, chinese): ") or "latin"
stroke_width = float(input("Enter the stroke width (default 0): ") or "0")

trueTypeFont = TTFont(font_path, fontNumber=0)
cmap = trueTypeFont.getBestCmap()

text = ""

charBytes = {
    "latin": [
        { "start": 33, "end": 126 },
        { "start": 161, "end": 161 },
        { "start": 163, "end": 163 },
        { "start": 176, "end": 180 },
        { "start": 191, "end": 214 },
        { "start": 217, "end": 221 },
        { "start": 223, "end": 253 },
        { "start": 255, "end": 259 }
    ],
    "cyrillic": [
        { "start": 1024, "end": 1118 }
    ]
}

byteRanges = None

#TODO basic latin characters required for all languages
if font_language == "chinese":
    byteRanges = decimal_converter.getDecimalsFromFile(f"{font_language}.txt")
    CELL_WIDTH = 64
    CELL_HEIGHT = 64
    BOLD_STROKE_WIDTH = 1
elif font_language in charBytes:
    byteRanges = charBytes[font_language]
else:
    input("Invalid language")
    sys.exit()

for byteRange in byteRanges:
    for byte in range(byteRange["start"], byteRange["end"] + 1):
        text += chr(byte)

charsToRemove = ""

for char in text:
    if not getIsCharacterSupported(cmap, char):
        charsToRemove += char


if len(charsToRemove) > 0:
    text = re.sub(f"[{charsToRemove}]", "", text)

print(f"Total Characters: {len(text)}")
IMAGE_HEIGHT = (len(text) * CELL_WIDTH) / IMAGE_WIDTH * CELL_HEIGHT


if font_language == "latin" or font_language == "cyrillic":
    IMAGE_HEIGHT /= 2

IMAGE_HEIGHT = max(IMAGE_HEIGHT, 256)


for i in range(1, 14):
    if pow(2, i) >= IMAGE_HEIGHT:
        IMAGE_HEIGHT = pow(2, i)
        break

print(f"Dimensions: {IMAGE_WIDTH}x{IMAGE_HEIGHT} ({CELL_WIDTH}x{CELL_HEIGHT})")


if not os.path.exists(font_name):
    os.makedirs(font_name)


font = None

try:
    font = ImageFont.truetype(font_path, size=100)
        
    font_size = 50
    test_font = ImageFont.truetype(font_path, font_size)
        
    while font_size <= 150:
        test_font = ImageFont.truetype(font_path, font_size)
        _, top, _, bottom = test_font.getbbox('M')
        test_height = bottom - top
        if test_height >= CELL_HEIGHT * 0.50:  # 50% of cell height for padding
            break
        font_size += 1
        
    font = ImageFont.truetype(font_path, font_size)
    print(f"Using font size: {font_size}")
except Exception as e:
    input(f"Error: {str(e)}")
    sys.exit(1)

characters = None

for i in STROKE_WIDTHS:
    
    characters = createFontImage(f"{font_name}/{font_name}_{i}", characters, "regular", (0, 0, 0, 0), (255, 255, 255, 255), text, font, strokeWidth=stroke_width+i, strokeWidthKey=i)
    createFontImage(f"{font_name}/{font_name}Bold_{i}", characters, "bold", (0, 0, 0, 0), (255, 255, 255, 255), text, font, strokeWidth=stroke_width+BOLD_STROKE_WIDTH+i*0.25, strokeWidthKey=i)
    createFontImage(f"{font_name}/{font_name}Italic_{i}", characters, "italic", (0, 0, 0, 0), (255, 255, 255, 255), text, font, isItalic=True, strokeWidth=stroke_width+i, strokeWidthKey=i)
    createFontImage(f"{font_name}/{font_name}BoldItalic_{i}", characters, "boldItalic", (0, 0, 0, 0), (255, 255, 255, 255), text, font, strokeWidth=stroke_width+BOLD_STROKE_WIDTH+i*0.25, isItalic=True, strokeWidthKey=i)

createFontImage(f"{font_name}/{font_name}_alpha", characters, "regular", (0, 0, 0, 255), (255, 255, 255, 255), text, font, fixedWidth=True, isAlpha=True, strokeWidth=stroke_width)
createFontImage(f"{font_name}/{font_name}Bold_alpha", characters, "bold", (0, 0, 0, 255), (255, 255, 255, 255), text, font, strokeWidth=stroke_width+BOLD_STROKE_WIDTH, fixedWidth=True, isAlpha=True)
createFontImage(f"{font_name}/{font_name}Italic_alpha", characters, "italic", (0, 0, 0, 255), (255, 255, 255, 255), text, font, isItalic=True, isAlpha=True, strokeWidth=stroke_width)
createFontImage(f"{font_name}/{font_name}BoldItalic_alpha", characters, "boldItalic", (0, 0, 0, 255), (255, 255, 255, 255), text, font, strokeWidth=stroke_width+BOLD_STROKE_WIDTH, isItalic=True, isAlpha=True)


# Font XML

root = ET.Element("font")

root.set("name", font_name)
root.set("language", font_language)

root_image = ET.SubElement(root, "image")
root_image.set("width", str(IMAGE_WIDTH))
root_image.set("height", str(IMAGE_HEIGHT))

root_cell = ET.SubElement(root, "cell")
root_cell.set("width", str(CELL_WIDTH))
root_cell.set("height", str(CELL_HEIGHT))

i = 0
for char in text:

    item = characters[ord(char)]

    character = ET.SubElement(root, "character")
    character.set("uvIndex", str(i))
    character.set("character", item["character"])
    character.set("byte", str(item["byte"]))

    if item["character"].isdigit():
        character.set("type", "numerical")
    elif item["character"].isalpha():
        character.set("type", "alphabetical")
    else:
        character.set("type", "special")

    regular = ET.SubElement(character, "regular")
    bold = ET.SubElement(character, "bold")
    italic = ET.SubElement(character, "italic")
    boldItalic = ET.SubElement(character, "boldItalic")

    for j in STROKE_WIDTHS:
    
        regularStroke = ET.SubElement(regular, "stroke")
        boldStroke = ET.SubElement(bold, "stroke")
        italicStroke = ET.SubElement(italic, "stroke")
        boldItalicStroke = ET.SubElement(boldItalic, "stroke")

        regularStroke.set("strokeWidth", str(j))
        boldStroke.set("strokeWidth", str(j))
        italicStroke.set("strokeWidth", str(j))
        boldItalicStroke.set("strokeWidth", str(j))

        regularStroke.set("x", str(item["regular"][str(j)]["x"]))
        regularStroke.set("y", str(item["regular"][str(j)]["y"]))
        regularStroke.set("width", str(item["regular"][str(j)]["width"]))

        boldStroke.set("x", str(item["bold"][str(j)]["x"]))
        boldStroke.set("y", str(item["bold"][str(j)]["y"]))
        boldStroke.set("width", str(item["bold"][str(j)]["width"]))

        italicStroke.set("x", str(item["italic"][str(j)]["x"]))
        italicStroke.set("y", str(item["italic"][str(j)]["y"]))
        italicStroke.set("width", str(item["italic"][str(j)]["width"]))

        boldItalicStroke.set("x", str(item["boldItalic"][str(j)]["x"]))
        boldItalicStroke.set("y", str(item["boldItalic"][str(j)]["y"]))
        boldItalicStroke.set("width", str(item["boldItalic"][str(j)]["width"]))

        if j == 0:
            
            regularStroke.set("left", str(item["regular"]["0"]["left"]))
            regularStroke.set("right", str(item["regular"]["0"]["right"]))
            boldStroke.set("left", str(item["bold"]["0"]["left"]))
            boldStroke.set("right", str(item["bold"]["0"]["right"]))
            italicStroke.set("left", str(item["italic"]["0"]["left"]))
            italicStroke.set("right", str(item["italic"]["0"]["right"]))
            boldItalicStroke.set("left", str(item["boldItalic"]["0"]["left"]))
            boldItalicStroke.set("right", str(item["boldItalic"]["0"]["right"]))

    i += 1

xml_str = minidom.parseString(ET.tostring(root)).toprettyxml(indent="  ")

with open(f"{font_name}/font.xml", "w", encoding="utf-8") as f:
    f.write(xml_str)

print(f"XML file '{font_name}/font.xml' created successfully!")
input("Font successfully generated")