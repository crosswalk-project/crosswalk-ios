/*
 * Copyright (c) 2013 Intel Corporation. All rights reserved.
 *
 * This program is licensed under the terms and conditions of the 
 * Apache License, version 2.0.  The full text of the Apache License is at
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 */

COLOR_BLUE = '#0000ff';
COLOR_GREEN = '#008000';
COLOR_RED = '#ff0000';
COLOR_GRAY = '#808080';
COLOR_BLACK = '#000';
COLOR_WHITE = '#fff';

// Padding to the coordinate
PADDING_LEFT = 20;
PADDING_RIGHT = 25;
PADDING_TOP = 20;
PADDING_BOTTOM = 15;

var system = navigator.system || xwalk.experimental.system;
var cpuPositions = [];

var Error = function(error) {
  console.log(error.message);
}

function drawRoundRect(ctx, x, y, width, height, radius, fill, stroke) {
  if (typeof stroke == "undefined" ) {
    stroke = true;
  }
  if (typeof radius == "undefined") {
    radius = 5;
  }
  ctx.beginPath();
  ctx.moveTo(x + radius, y);
  ctx.lineTo(x + width - radius, y);
  ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
  ctx.lineTo(x + width, y + height - radius);
  ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
  ctx.lineTo(x + radius, y + height);
  ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
  ctx.lineTo(x, y + radius);
  ctx.quadraticCurveTo(x, y, x + radius, y);
  ctx.closePath();

  if (stroke) {
    ctx.stroke();
  }
  if (fill) {
    ctx.fill();
  }        
}

function byteToHumanReadable(value) {
  if (value >= 1024 * 1024 * 1024) {
    return (value / (1024 * 1024 * 1024)).toFixed(2) + " GB";
  } else if (value >= 1024 * 1024) {
    return (value / (1024 * 1024)).toFixed(2) + " MB";
  } else if (value >= 1024) {
    return (value / 1024).toFixed(2) + " KB";
  } else {
    return value.toFixed(2) + (value > 1 ? " bytes" : " byte");
  }
}

function showCPU() {
  system.getCPUInfo().then(function(cpu) {
    var canvas = $('#cpu-graph')[0];
    var context = canvas.getContext('2d');

    canvas.width = window.innerWidth * 2 / 3; // Clear the whole canvas
    canvas.height = canvas.width / 2;
    // Draw the coordinate axis
    context.fillText('100', 0, PADDING_TOP / 2);
    context.fillText('Usage', PADDING_LEFT + 1, PADDING_TOP / 2);
    context.fillText('0', PADDING_LEFT / 2, canvas.height - PADDING_BOTTOM);
    context.fillText('Time', canvas.width - PADDING_RIGHT, canvas.height - 5);
    context.moveTo(PADDING_LEFT, 0);
    context.lineTo(PADDING_LEFT, canvas.height - PADDING_BOTTOM);
    context.moveTo(PADDING_LEFT, canvas.height - PADDING_BOTTOM);
    context.lineTo(canvas.width - PADDING_RIGHT / 2,
                   canvas.height - PADDING_BOTTOM);
    context.stroke();

    var graphWidth = canvas.width - PADDING_LEFT;
    var graphHeight = canvas.height - PADDING_BOTTOM;
    var y = graphHeight - cpu.load * graphHeight; 
    var len = cpuPositions.length;

    // Update each position
    if (len == 0) {
      var pos = {
        x: PADDING_LEFT + 1,
        y: y
      };
      cpuPositions[0] = pos;
    } else if (cpuPositions[len - 1].x < graphWidth) {
      var pos = {
        x: cpuPositions[len - 1].x + 10,
        y: y
      };
      cpuPositions[len] = pos;
    } else {
      var pos = {
        x: cpuPositions[len - 1].x,
        y: y
      };
      for (var i = 0; i < len - 1; ++i) {
        cpuPositions[i].y = cpuPositions[i + 1].y;
      }
      cpuPositions[len - 1] = pos;
    }
    context.fillRect(cpuPositions[0].x, cpuPositions[0].y, 1, 1);

    for (var i = 1; i < cpuPositions.length; ++i) {
      context.moveTo(cpuPositions[i - 1].x, cpuPositions[i - 1].y);
      context.lineTo(cpuPositions[i].x, cpuPositions[i].y);
    }
    context.stroke();

    $('#cpu-info').html('The CPU of this device is ' + cpu.archName +
        ', <br />which has ' + cpu.numOfProcessors + ' processor' +
        (cpu.numOfProcessors > 1 ? 's' : '') + '<br /><br />');
  }, Error);
}

function showMemory() {
  system.getMemoryInfo().then(function(memory) {
    var canvas = $('#memory-bank')[0];
    var context = canvas.getContext('2d');
    var radius = 20;

    canvas.width = window.innerWidth * 2 / 3;
    canvas.height = canvas.width / 3;
    // First clear the whole bank
    context.fillStyle = COLOR_GRAY;
    drawRoundRect(context, 0, 0, canvas.width, canvas.height, radius, true);

    // Then draw the used memory in another color
    var used = 1 - memory.availCapacity / memory.capacity; 
    var width = canvas.width * used;
    if (used > 0.9) {           // Red to mark there is almost no more memory
      context.fillStyle = COLOR_RED;
    } else {
      context.fillStyle = COLOR_GREEN;
    }
    drawRoundRect(context, 0, 0, width, canvas.height, radius, true);

    if (width < canvas.width - radius) {
      context.fillRect(width - radius, 0, radius + 1, canvas.height);
    }
    $('#memory-info').html('Used memory: ' +
        byteToHumanReadable(memory.capacity - memory.availCapacity) +
        '<br />Total memory: ' + byteToHumanReadable(memory.capacity) + 
        '<br /><br />');
  }, Error);
}
 
function showStorage() {
  system.getStorageInfo().then(function(storageInfo) {
    var storages = storageInfo.storages;
    var numStorage = storages.length;
    var node = $('#storage');

    node.empty();
    node.append('<h3>Storage State</h3>');
    node.append('There ' + (numStorage > 1 ? 'are ' : 'is ') +
        numStorage + ' storage device' + 
        (numStorage > 1 ? 's' : '') + ':<br />');

    for (var i = 0; i < numStorage; ++i) {
      node.append((i + 1) + '. ');
      node.append(storages[i].name + '<br />');
      node.append('<canvas id="storage' + storages[i].id + '"></canvas><br />');
      var canvas = $('#storage' + storages[i].id)[0];
      var context = canvas.getContext('2d');
      var radius = 5;

      canvas.width = window.innerWidth * 2 / 3;
      canvas.height = canvas.width / 6;
      context.fillStyle = COLOR_GRAY;
      drawRoundRect(context, 0, 0, canvas.width, canvas.height, radius, true);

      // Draw the used storage in another color
      var used = 1 - storages[i].availCapacity / storages[i].capacity; 
      var width = canvas.width * used;
      if (used > 0.9) {
        context.fillStyle = COLOR_RED;
      } else {
        context.fillStyle = COLOR_GREEN;
      }
      drawRoundRect(context, 0, 0, width, canvas.height, radius, true);

      if (width < canvas.width - radius) {
        context.fillRect(width - radius, 0, radius + 1, canvas.height);
      }

      node.append('It\'s ' + storages[i].type + ' and its capacity is ' +
          byteToHumanReadable(storages[i].capacity) + '.<br /><br />');
    }
  }, Error);
}

function showDisplay() {
  system.getDisplayInfo().then(function(displayInfo) {
    var displays = displayInfo.displays;
    var numDisplay = displays.length;
    var node = $('#display');

    node.empty();
    node.append('<h3>Display State</h3>');

    if (numDisplay == 0) {
      node.append('Cannot get display information for this device<br/>');
      return;
    }
    node.append('There ' + (numDisplay > 1 ? 'are ' : 'is ') +
        numDisplay + ' display device' +
        (numDisplay > 1 ? 's' : '') + ':<br />');

    for (var i = 0; i < numDisplay; ++i) {
      node.append((i + 1) + '. ');
      node.append(displays[i].name + '<br />');
      node.append('<canvas id="display' + displays[i].id +
          '"></canvas><br />');
      var width = displays[i].availWidth / 10;
      var height = displays[i].availHeight / 10;
      var canvas = $('#display' + displays[i].id)[0];
      var context = canvas.getContext('2d');

      canvas.height = height + 40;
      canvas.width = width + 40;
      context.fillText(displays[i].availWidth + 'px', width / 2,
          PADDING_TOP / 2);
      context.fillText(displays[i].availHeight + 'px', width + 5, height / 2);
      // Draw a rectangle as the display screen
      context.moveTo(width, PADDING_TOP);
      context.lineTo(0, PADDING_TOP); 
      context.moveTo(0, PADDING_TOP);
      context.lineTo(0, height);
      context.moveTo(0, height);
      context.lineTo(width, height);
      context.moveTo(width, height);
      context.lineTo(width, PADDING_TOP);
      context.stroke();

      node.append('It\'s ' + 
          (displays[i].isPrimary ? 'a primary ' : 'an auxiliary ') +
          ' display and is ' + 
          (displays[i].isInternal ? 'internal' : 'external') +
          '.<br /><br />');
    }
  }, Error);
}

function checkUploadFile() {
  system.getAVCodecs().then(function(avcodecs) {
    var msgNode = $('#upload-message');
    msgNode.css('word-wrap', 'break-word');

    var audios = avcodecs.audioCodecs;
    var videos = avcodecs.videoCodecs;
 
    if (typeof audios == 'undefined' || typeof videos == 'undefined') {
      msgNode.html("Cannot get codecs from this device");
      return;
    }
    var file = document.getElementById('file-to-upload').files[0];
    var mimeType = file.type.split('/');
    var type = mimeType[0];
    var format = mimeType[1];

    if (type == "audio") {
      msgNode.css('color', COLOR_BLACK);
      msgNode.append("This file is an audio file. According to the " +
          "codecs of this device, ");

      for (var i = 0; i < audios.length; ++i) {
        if (audios[i].format != format.toUpperCase()) {
          continue;
        }
        if (!audios[i].encode) {
          msgNode.css('color', COLOR_BLUE);
          msgNode.append("this format is not supported encoding by " +
              "this device, so it will not be encoded before uploading it to " +
              "the cloud server<br />");
          break;
        }
        msgNode.css('color', COLOR_GREEN);
        msgNode.append("this format is supported encoding by this device. " +
            "so it will be encoded before uploading it to the cloud server" +
            "<br />");
        break;
      }
      if (i == audios.length) {
        msgNode.css('color', COLOR_BLUE);
        msgNode.append("this format is not supported by this device, so it " +
            "will not be encoded before uploading it to the cloud " +
            "server<br />");
      }
    } else if (type == "video") {
      msgNode.css('color', COLOR_BLACK);
      msgNode.append("This file is an video file. According to the " +
          "codecs of this device, ");

      for (var i = 0; i < videos.length; ++i) {
        if (videos[i].format != format.toUpperCase()) {
          continue;
        }
        if (!videos[i].encode) {
          msgNode.css('color', COLOR_BLUE);
          msgNode.append("this format is not supported encoding by this " +
              "device, so it will not be encoded before uploading it to " +
              "the cloud server<br />");
          break;
        }
        msgNode.css('color', COLOR_GREEN);
        msgNode.append("this format is supported encoding by this device, " +
            " so it will be encoded before uploading it to the cloud server" +
            "<br />");
        break;
      }
      if (i == audios.length) {
        msgNode.css('color', COLOR_BLUE);
        msgNode.append("this format is not supported by this device, " +
            "so it will not be encoded before uploading it to the cloud " +
            "server<br />");
      }
    } else {
      msgNode.css('color', COLOR_RED);
      msgNode.html("This file is not a recognized audio or video file!");
    }
  }, Error);
}

function scrollToElement(selector, time, verticalOffset) {
  var time = typeof(time) != 'undefined' ? time : 500;
  var verticalOffset = typeof(verticalOffset) != 'undefined' ? verticalOffset : 0;
  var offsetTop = $(selector).offset().top + verticalOffset;
  
  $('html, documentElement').animate({
    scrollTop: offsetTop
  }, time);
}

$(document).ready(function() {
  // Scroll to the specific block
  $('#nav-cpu').click(function () {
    scrollToElement('#cpu', 500, -($('#cpu').height() / 2));
  });
  $('#nav-memory').click(function () {
    scrollToElement('#memory', 500, -($('#memory').height() / 2));
  });
  $('#nav-storage').click(function () {
    scrollToElement('#storage', 500, -($('#storage').height() / 2));
  });
  $('#nav-display').click(function () {
    scrollToElement('#display', 500, -($('#display').height() / 2));
  });
  $('#nav-avcodecs').click(function () {
    scrollToElement('#avcodecs', 500, -($('#avcodecs').height() / 2));
  });

  setInterval(function monitor() {
    showCPU();
    showMemory();
    showStorage();
    showDisplay();
    return monitor;
  }(), 1000);

  $('#file-to-upload').change(function() {
    checkUploadFile();
  });
});
