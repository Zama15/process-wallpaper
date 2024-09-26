import re
import json
import os
import matplotlib.pyplot as plt
import random
import subprocess
from wordcloud import WordCloud

commandList = []

with open("top.out", "r") as topFile:
    topOutput = topFile.read().split("\n")[7:]

    for line in topOutput[:-1]:
        line = re.sub(r'\s+', ' ', line).strip()
        fields = line.split(" ")

        try:
            if fields[11].count("/") > 0:
                command = fields[11].split("/")[0]
            else:
                command = fields[11]

            cpu = float(fields[8].replace(",", "."))
            mem = float(fields[9].replace(",", "."))

            if command != "top":
                commandList.append((command, cpu, mem))
        except:
            pass


commandDict = {}

for command, cpu, mem in commandList:
    if command in commandDict:
        commandDict[command][0] += cpu
        commandDict[command][1] += mem
    else:
        commandDict[command] = [cpu + 1, mem + 1]


resourceDict = {}

for command, [cpu, mem] in commandDict.items():
    resourceDict[command] = (cpu ** 2 + mem ** 2) ** 0.5

#
# Open config file to get values
#
configJSON = json.loads(open("config.json", "r").read())

#
# Define a getter function to screen resolution
#
def get_screen_resolution():
    try:
        # Attempt to get screen resolution using xrandr
        output = subprocess.check_output(["xrandr"], universal_newlines=True, stderr=subprocess.DEVNULL)
        for line in output.split('\n'):
            if '*' in line:
                width, height = line.split()[0].split('x')
                return int(width), int(height)
    except (subprocess.CalledProcessError, FileNotFoundError):
        # xrandr command failed or xrandr is not installed
        print("Note: xrandr is not available. Falling back to config file.")
    
    # If xrandr failed or we couldn't parse its output, use config file
    return configJSON['resolution']['width'], configJSON['resolution']['height']

width, height = get_screen_resolution()

#
# Define a color function for words
#
def color_func(word, font_size, position, orientation, random_state=None, **kwargs):
    if "colors" in configJSON["wordcloud"]:
        return random.choice(configJSON["wordcloud"]["colors"])
    else:
        return plt.cm.viridis(random_state.rand())

# Create the wallpaper with WordCloud Obj
wc = WordCloud(
    background_color=configJSON["wordcloud"]["background"],
    width=width,
    height=height,
    color_func=color_func,
    margin=configJSON["wordcloud"]["margin"]
).generate_from_frequencies(resourceDict)

# Save wallpaper
wc.to_file("wallpaper.png")


