// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/

function appendArcPath(base, radius, startAngle, endAngle) {
      var points = 30;

      var angle = d3.scaleLinear()
          .domain([0, points - 1])
          .range([startAngle, endAngle]);

      var line = d3.radialLine()
          .curve(d3.curveBasis)
          .radius(radius)
          .angle(function(d, i) { return angle(i); });

      return base.append("path").datum(d3.range(points))
          .attr("d", line);
}

function drawCourt(base, width) {
      var courtWidth = 50,
          visibleCourtLength = 40,
          keyWidth = 16,
          threePointRadius = 22.1458,
          threePointSideRadius = 22,
          // On the WNBA website it says 63" (5.25 feet), but that doesn't connect
          threePointCutoffLength = 7,
          freeThrowLineLength = 19,
          freeThrowCircleRadius = 6,
          basketProtrusionLength = 4,
          basketDiameter = 1.5,
          basketWidth = 6,
          restrictedCircleRadius = 4,
          keyMarkWidth = 0.5;

      var base = base
        .attr('width', width)
        .attr('viewBox', "0 0 " + courtWidth + " " + visibleCourtLength)
        .append('g')
          .attr('class', 'shot-chart-court');

      base.append("rect")
        .attr('class', 'shot-chart-court-key')
        .attr("x", (courtWidth / 2 - keyWidth / 2))
        .attr("y", (visibleCourtLength - freeThrowLineLength))
        .attr("width", keyWidth)
        .attr("height", freeThrowLineLength);

      base.append("line")
        .attr('class', 'shot-chart-court-baseline')
        .attr("x1", 0)
        .attr("y1", visibleCourtLength)
        .attr("x2", courtWidth)
        .attr("y2", visibleCourtLength);

      var tpAngle = Math.atan(threePointSideRadius /
        (threePointCutoffLength - basketProtrusionLength - basketDiameter/2));
      appendArcPath(base, threePointRadius, -1 * tpAngle, tpAngle)
        .attr('class', 'shot-chart-court-3pt-line')
        .attr("transform", "translate(" + (courtWidth / 2) + ", " +
          (visibleCourtLength - basketProtrusionLength - basketDiameter / 2) +
          ")");

      [1, -1].forEach(function (n) {
        base.append("line")
          .attr('class', 'shot-chart-court-3pt-line')
          .attr("x1", courtWidth / 2 + threePointSideRadius * n)
          .attr("y1", visibleCourtLength - threePointCutoffLength)
          .attr("x2", courtWidth / 2 + threePointSideRadius * n)
          .attr("y2", visibleCourtLength);
      });

      appendArcPath(base, restrictedCircleRadius, -1 * Math.PI/2, Math.PI/2)
        .attr('class', 'shot-chart-court-restricted-area')
        .attr("transform", "translate(" + (courtWidth / 2) + ", " +
          (visibleCourtLength - basketProtrusionLength - basketDiameter / 2) + ")");

      appendArcPath(base, freeThrowCircleRadius, -1 * Math.PI/2, Math.PI/2)
        .attr('class', 'shot-chart-court-ft-circle-top')
        .attr("transform", "translate(" + (courtWidth / 2) + ", " +
          (visibleCourtLength - freeThrowLineLength) + ")");

      appendArcPath(base, freeThrowCircleRadius, Math.PI/2, 1.5 * Math.PI)
        .attr('class', 'shot-chart-court-ft-circle-bottom')
        .attr("transform", "translate(" + (courtWidth / 2) + ", " +
          (visibleCourtLength - freeThrowLineLength) + ")");

      [7, 8, 11, 14].forEach(function (mark) {
        [1, -1].forEach(function (n) {
          base.append("line")
            .attr('class', 'shot-chart-court-key-mark')
            .attr("x1", courtWidth / 2 + keyWidth / 2 * n + keyMarkWidth * n)
            .attr("y1", visibleCourtLength - mark)
            .attr("x2", courtWidth / 2 + keyWidth / 2 * n)
            .attr("y2", visibleCourtLength - mark)
        });
      });

      base.append("line")
        .attr('class', 'shot-chart-court-backboard')
        .attr("x1", courtWidth / 2 - basketWidth / 2)
        .attr("y1", visibleCourtLength - basketProtrusionLength)
        .attr("x2", courtWidth / 2 + basketWidth / 2)
        .attr("y2", visibleCourtLength - basketProtrusionLength)

      base.append("circle")
        .attr('class', 'shot-chart-court-hoop')
        .attr("cx", courtWidth / 2)
        .attr("cy", visibleCourtLength - basketProtrusionLength - basketDiameter / 2)
        .attr("r", basketDiameter / 2)
}

function makePlayerShotChart(element, data, namespace) {
  var width = 500;
  var height = 500;
  var svg = element;

  var sizeScale = d3.scaleLinear()
                    .domain([0, d3.max(data, function(d) { return +d.made + +d.missed; })])
                    .range([0, 1]);

  var colorScale = d3.scaleLinear()
                     .domain([0, 0.944, 3])
                     .range(['#5458A2', '#FADC97', '#B02B48']);

  var circles = svg.selectAll('circle.shot-chart-point').data(data);

  d3.select(".d3-tip-" + namespace).remove();

  var tip = d3.tip()
    .attr('class', 'd3-tip d3-tip-' + namespace)
    .html(function(d) {
      return d.made + '/' + (d.missed + d.made);
    });

  svg.call(tip);

  if (svg.select('.shot-chart-court').empty()) {
    drawCourt(svg, width);
  }

  circles.enter()
         .append('circle')
         .attr('class', 'shot-chart-point')
         .merge(circles)
         .attr('cx', function(d) {
           return d.x + 25;
         })
         .attr('cy', function(d) {
           return 35 - d.y;
         })
         .attr('r', function(d) {
           return sizeScale(+d.made + +d.missed);
         })
         .attr('fill', function(d) {
           return colorScale(d.pts_per_shot);
         })
         .on('mouseover', function(d) {
           (tip.show.bind(this))(d);
           var rect = d3.select('.d3-tip-player').node().getBoundingClientRect();
           tip.style('top', (d3.event.pageY - rect.height - 10) + 'px')
              .style('left', (d3.event.pageX - (rect.width / 2)) + 'px');
         })
         .on('mousemove', function(d) {
           var rect = d3.select('.d3-tip-player').node().getBoundingClientRect();
           tip.style('top', (d3.event.pageY - rect.height - 10) + 'px')
              .style('left', (d3.event.pageX - (rect.width / 2)) + 'px');
         })
         .on('mouseout', tip.hide);

  circles.exit().remove();
}

function makeTeamEffectShotChart(element, data, namespace) {
  var width = 500;
  var height = 500;
  var svg = element;

  // NB: 1 and -1 are the theoretical max and min, but they will NEVER
  // occur except for in statistical noise. I arbitrarily chose 0.05 and -0.05 as
  // a reasonable expectation for highest actual player impact.
  var sizeScale = d3.scaleLinear()
                    .domain([-1, -0.05, 0, 0.05, 1])
                    .range([0, 0, 2, 4, 4]);

  // NB: 3 and -3 are the theoretical max and min, but they will almost never
  // occur except for in statistical noise. I arbitrarily chose 1.5 and -1.5 as
  // a reasonable expectation for highest actual player impact.
  var colorScale = d3.scaleLinear()
                     .domain([-3, -1.5, 0, 1.5, 3])
                     .range(['#5458A2', '#5458A2', '#FADC97', '#B02B48', '#B02B48']);

  var impacts = data.map(function(d) {
    return Math.abs((d.on_court.frequency * d.on_court.pts_per_shot) - (d.off_court.frequency * d.off_court.pts_per_shot));
  });

  var opacityScale = d3.scaleLinear()
                       .domain(d3.extent(impacts))
                       .range([0.35, 1]);

  var rings = svg.selectAll('path.ring').data(data);
  var dashedRings = svg.selectAll('path.dashed-ring').data(data);

  d3.select(".d3-tip-" + namespace).remove();

  var tip = d3.tip()
    .attr('class', 'd3-tip d3-tip-' + namespace)
    .html(function(d) {
      return 'On Court: ' + (d.on_court.frequency * 100).toFixed(1) + '% of shots, ' + (((d.on_court.made / (d.on_court.missed + d.on_court.made)) || 0) * 100).toFixed(1) + '% made<br>' +
             'Off Court: ' + (d.off_court.frequency * 100).toFixed(1) + '% of shots, ' + (((d.off_court.made / (d.off_court.missed + d.off_court.made)) || 0) * 100).toFixed(1) + '% made';
    });

  svg.call(tip);

  if (svg.select('.shot-chart-court').empty()) {
    drawCourt(svg, width);
  }

  var arc = d3.arc()
    .startAngle(0)
    .endAngle(Math.PI * 2);

  var dashedArc = d3.arc()
    .startAngle(0)
    .endAngle(Math.PI * 2);

  rings.enter()
         .append('path')
         .attr('class', 'ring')
         .merge(rings)
         .each(function(d) {
           if (d.frequency_delta > 0) {
             d.innerRadius = sizeScale(0);
             d.outerRadius = sizeScale(d.frequency_delta);
           } else {
             d.outerRadius = sizeScale(0);
             d.innerRadius = sizeScale(d.frequency_delta);
             if (d.innerRadius === 0) {
               d.innerRadius = 0.2;
             }
           }
         })
         .attr('transform', function(d) {
           return 'translate(' + (d.x + 25) + ', ' + (35 - d.y) + ')';
         })
         .attr('d', arc)
         .attr('fill', function(d) {
           return colorScale(d.pps_delta);
         })
         .attr('stroke', function(d) {
           return colorScale(d.pps_delta);
         })
         .attr('opacity', function(d) {
           var impact = Math.abs((d.on_court.frequency * d.on_court.pts_per_shot) - (d.off_court.frequency * d.off_court.pts_per_shot));
           return opacityScale(impact);
         })
         .on('mouseover', function(d) {
           (tip.show.bind(this))(d);
           var y = d3.event.pageY;
           var x = d3.event.pageX;
           var rect = d3.select('.d3-tip-' + namespace).node().getBoundingClientRect();
           tip.style('top', (y - rect.height - 10) + 'px')
              .style('left', (x - (rect.width / 2)) + 'px');
         })
         .on('mousemove', function(d) {
           var y = d3.event.pageY;
           var x = d3.event.pageX;
           var rect = d3.select('.d3-tip-' + namespace).node().getBoundingClientRect();
           tip.style('top', (y - rect.height - 10) + 'px')
              .style('left', (x - (rect.width / 2)) + 'px');
         })
         .on('mouseout', tip.hide);

  rings.exit().remove();

  dashedRings.enter()
    .append('path')
    .attr('class', 'dashed-ring')
    .merge(dashedRings)
    .each(function(d) {
      if (d.frequency_delta > 0) {
        d.innerRadius = sizeScale(0) - 0.08;
        d.outerRadius = sizeScale(0) - 0.08;
      } else {
        d.innerRadius = sizeScale(0) + 0.08;
        d.outerRadius = sizeScale(0) + 0.08;
      }
    })
    .attr('transform', function(d) {
      return 'translate(' + (d.x + 25) + ', ' + (35 - d.y) + ')';
    })
    .attr('d', dashedArc);

  dashedRings.exit().remove();
}

function makeDistanceChart(svg, data) {
  var width = 500;
  var height = 450;
  var margin = {
    top: 10,
    bottom: 40,
    left: 40,
    right: 0
  };

  svg.attr('width', width)
      .attr('height', height)
      .attr('viewBox', "0 0 " + width + " " + height);

  var chartHeight = height - margin.top - margin.bottom;
  var chartWidth = width - margin.left - margin.right;

  var g = svg.append('g')
             .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')
             .attr('height', chartHeight)
             .attr('width', chartWidth);

  var xScale = d3.scaleLinear()
    .range([chartWidth, 0])
    .domain([-1, d3.max(data, function(d) { return d.distance; }) + 2]);

  var yScale = d3.scaleLinear()
      .range([chartHeight, 0])
      .domain([-0.1, d3.max(data, function(d) { return d.pts_per_shot; }) + 0.1]);

  var rScale = d3.scaleLinear()
      .domain([0, d3.max(data, function(d) { return d.made + d.missed; })])
      .range([0, 25]);

  var colorScale = d3.scaleLinear()
                     .domain([0, 0.944, 3])
                     .range(['#5458A2', '#FADC97', '#B02B48']);

  svg.append("g")
      .attr("transform", "translate(" + margin.left + "," + (chartHeight + margin.top) + ")")
      .call(
        d3.axisBottom(xScale)
          .ticks(5)
          .tickFormat(function(d) {
            return Math.round(d) + 'ft';
          })
      );

  svg.append("g")
      .attr("transform", "translate(" + (margin.left - 30) + "," + ((chartHeight / 2) + margin.top) + ")")
      .append("text")
        .attr('transform', 'rotate(-90)')
        .attr("text-anchor", "middle")
        .text('Points Per Shot');

  svg.append("g")
      .attr("transform", "translate(" + (margin.left + (chartWidth / 2)) + "," + (chartHeight + margin.top + 30) + ")")
      .append("text")
        .attr("text-anchor", "middle")
        .text('Distance');

  svg.append("g")
      .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')
      .call(d3.axisLeft(yScale).ticks(5));

  d3.select(".d3-tip-distance").remove();

  var tip = d3.tip()
    .attr('class', 'd3-tip d3-tip-distance')
    .html(function(d) {
      return d.made + '/' + (d.missed + d.made);
    });

  svg.call(tip);

  var circles = g.selectAll('circle.dot').data(data);

  circles.enter()
    .append('circle')
    .attr('class', 'dot')
    .merge(circles)
    .attr('cx', function(d) {
      return xScale(d.distance)
    })
    .attr('cy', function(d) {
      return yScale(d.pts_per_shot);
    })
    .attr('r', function(d) {
      return rScale(d.made + d.missed);
    })
    .attr('fill', function(d) {
      return colorScale(d.pts_per_shot);
    })
    .on('mouseover', function(d) {
      (tip.show.bind(this))(d);
      var rect = d3.select('.d3-tip-distance').node().getBoundingClientRect();
      tip.style('top', (d3.event.pageY - rect.height - 10) + 'px')
         .style('left', (d3.event.pageX - (rect.width / 2)) + 'px');
    })
    .on('mousemove', function(d) {
      var rect = d3.select('.d3-tip-distance').node().getBoundingClientRect();
      tip.style('top', (d3.event.pageY - rect.height - 10) + 'px')
         .style('left', (d3.event.pageX - (rect.width / 2)) + 'px');
    })
    .on('mouseout', tip.hide);;

  circles.exit().remove();
}

// Shooting section

function getPlayerShotChart() {
  $('#player-viz-container').spin(true);
  $.getJSON('/players/' + gon.player_id + '/shot_chart_data/' + gon.season, function(data) {
    $('#player-viz-container').spin(false);
    makePlayerShotChart(d3.select('#player-viz'), data, 'player');
  });
}

function getDistanceChart() {
  $('#distance-viz-container').spin(true);
  $.getJSON('/players/' + gon.player_id + '/distance_chart_data/' + gon.season, function(data) {
    $('#distance-viz-container').spin(false);
    makeDistanceChart(d3.select('#distance-viz'), data);
  });
}

function getTeamShotChart() {
  $('#team-viz-container').spin(true);
  $.getJSON('/players/' + gon.player_id + '/team_effect_shot_chart_data/' + gon.season, function(data) {
    $('#team-viz-container').spin(false);
    makeTeamEffectShotChart(d3.select('#team-viz'), data, 'team');
  });
}

function getOpposingTeamShotChart() {
  $('#opposing-team-viz-container').spin(true);
  $.getJSON('/players/' + gon.player_id + '/opposing_team_effect_shot_chart_data/' + gon.season, function(data) {
    $('#opposing-team-viz-container').spin(false);
    makeTeamEffectShotChart(d3.select('#opposing-team-viz'), data, 'opposing-team');
  });
}
