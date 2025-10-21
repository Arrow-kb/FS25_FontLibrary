def showExceptionAndExit(exc_type, exc_value, tb):
    import traceback
    traceback.print_exception(exc_type, exc_value, tb)
    input("Press key to exit.")
    sys.exit(-1)


from PIL import Image, ImageDraw, ImageFont
from fontTools.ttLib import TTFont
import xml.etree.ElementTree as ET
import xml.dom.minidom as minidom
import sys
import os
import subprocess
import re
import math

sys.excepthook = showExceptionAndExit


CELL_WIDTH = 128
CELL_HEIGHT = 128


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
    
    for y in range(startY, startY + 128 > height and height or (startY + 128)):
        for x in range(startX, startX + 128 > width and width or (startX + 128)):
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


def createFontImage(filename, characters, varType, bgColour, textColour, text, font, strokeWidth=0, fixedWidth=False, isItalic=False):

    fixedWidth = fixedWidth or isItalic

    IMAGE_WIDTH = 8192
    IMAGE_HEIGHT = fixedWidth and 512 or 256

    buildCharacterDb = characters == None
    characters = characters or {}

    try:
        image = Image.new('RGBA', (IMAGE_WIDTH, IMAGE_HEIGHT), bgColour)
        draw = ImageDraw.Draw(image)
        
        current_x = 0
        row = 0
        max_rows = IMAGE_HEIGHT // CELL_HEIGHT

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
                draw.text((current_x + (fixedWidth and (CELL_WIDTH / 2) or 4), y_pos + 64), char, font=font, fill=textColour, anchor = (fixedWidth and "mm" or "lm"), stroke_width=strokeWidth)

            byte = ord(char)

            if buildCharacterDb:

                characters[byte] = {
                    "character": char,
                    "byte": byte,
                    varType: {
                        "width": isItalic and italicWidth or char_width,
                        "x": current_x + (isItalic and italicXOffset or (fixedWidth and 0) or 4),
                        "y": y_pos
                    }
                }

            else:

                characters[byte][varType] = {
                    "width": isItalic and italicWidth or char_width,
                    "x": current_x + (isItalic and italicXOffset or (fixedWidth and 0) or 4),
                    "y": y_pos
                }
                

            # 4px padding to char_width to prevent hooked characters appearing under adjacent characters
            current_x += fixedWidth and CELL_WIDTH or (char_width + strokeWidth * 2 + 8)

            
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
font_name = input("Enter the id of the font (eg: GENERIC):")
font_language = input("Enter the language of the font (latin, cyrillic):")

trueTypeFont = TTFont(font_path)
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

if not font_language in charBytes:
    input("Invalid language")
    sys.exit()

for byteRange in charBytes[font_language]:
    for byte in range(byteRange["start"], byteRange["end"] + 1):
        text += chr(byte)

charsToRemove = ""

for char in text:
    if not getIsCharacterSupported(cmap, char):
        charsToRemove += char


if len(charsToRemove) > 0:
    text = re.sub(f"[{charsToRemove}]", "", text)



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

    
characters = createFontImage(f"{font_name}/{font_name}", None, "regular", (0, 0, 0, 0), (255, 255, 255, 255), text, font)
createFontImage(f"{font_name}/{font_name}Bold", characters, "bold", (0, 0, 0, 0), (255, 255, 255, 255), text, font, strokeWidth=2)
createFontImage(f"{font_name}/{font_name}Italic", characters, "italic", (0, 0, 0, 0), (255, 255, 255, 255), text, font, isItalic=True)
createFontImage(f"{font_name}/{font_name}BoldItalic", characters, "boldItalic", (0, 0, 0, 0), (255, 255, 255, 255), text, font, strokeWidth=2, isItalic=True)
createFontImage(f"{font_name}/{font_name}_alpha", None, "regular", (0, 0, 0, 255), (255, 255, 255, 255), text, font, fixedWidth=True)
createFontImage(f"{font_name}/{font_name}Bold_alpha", None, "bold", (0, 0, 0, 255), (255, 255, 255, 255), text, font, strokeWidth=2, fixedWidth=True)
createFontImage(f"{font_name}/{font_name}Italic_alpha", None, "italic", (0, 0, 0, 255), (255, 255, 255, 255), text, font, isItalic=True)
createFontImage(f"{font_name}/{font_name}BoldItalic_alpha", None, "boldItalic", (0, 0, 0, 255), (255, 255, 255, 255), text, font, strokeWidth=2, isItalic=True)


# Font XML

root = ET.Element("font")

root.set("name", font_name)
root.set("width", "64")
root.set("language", font_language)

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

    regular.set("x", str(item["regular"]["x"]))
    regular.set("y", str(item["regular"]["y"]))
    regular.set("width", str(item["regular"]["width"]))

    bold.set("x", str(item["bold"]["x"]))
    bold.set("y", str(item["bold"]["y"]))
    bold.set("width", str(item["bold"]["width"]))

    italic.set("x", str(item["italic"]["x"]))
    italic.set("y", str(item["italic"]["y"]))
    italic.set("width", str(item["italic"]["width"]))

    boldItalic.set("x", str(item["boldItalic"]["x"]))
    boldItalic.set("y", str(item["boldItalic"]["y"]))
    boldItalic.set("width", str(item["boldItalic"]["width"]))

    i += 1

xml_str = minidom.parseString(ET.tostring(root)).toprettyxml(indent="  ")

with open(f"{font_name}/font.xml", "w", encoding="utf-8") as f:
    f.write(xml_str)

print(f"XML file '{font_name}/font.xml' created successfully!")
input("Font successfully generated")