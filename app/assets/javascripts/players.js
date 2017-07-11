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

function drawCourt(base, width, opts) {
      var courtWidth = 50,
          visibleCourtLength = opts.visibleCourtLength || 40,
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

  var sizeScale = d3.scaleSqrt()
                    .domain([0, d3.max(data, function(d) { return +d.made + +d.missed; })])
                    .range([0, 1]);

  var colorScale = d3.scaleLinear()
                     .domain([0, 0.944, 3])
                     .range(['#5458A2', '#FADC97', '#B02B48']);

  if (svg.select('.legend').empty()) {
    var colorLegend = d3.legendColor()
      .scale(colorScale)
      .shape('circle')
      .shapeRadius(0.5)
      .shapePadding(0.5)
      .cells([0, 0.944, 3])
      .labels(['ice cold', 'league average', 'on fire']);

    svg.append('g')
      .attr('class', 'legend')
      .attr("transform", "translate(0.75, 0.75)")
      .call(colorLegend);

    svg.selectAll('.legendCells .label').attr('transform', 'translate(1, 0.3)');
  }

  var circles = svg.selectAll('circle.shot-chart-point').data(data, function(d) {return d.loc_x + ',' + d.loc_y});

  d3.select(".d3-tip-" + namespace).remove();

  var tip = d3.tip()
    .attr('class', 'd3-tip d3-tip-' + namespace)
    .html(function(d) {
      return d.made + '/' + (d.missed + d.made);
    });

  svg.call(tip);

  if (svg.select('.shot-chart-court').empty()) {
    drawCourt(svg, width, {});
  }

  circles.enter()
    .append('circle')
    .attr('class', 'shot-chart-point')
    .attr('r', 0)
    .merge(circles)
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
      .on('mouseout', tip.hide)
      .attr('cx', function(d) {
        return d.x + 25;
      })
      .attr('cy', function(d) {
        return 35 - d.y;
      })
      .attr('fill', function(d) {
        return colorScale(d.pts_per_shot);
      })
      .transition()
        .duration(750)
        .delay(function(d) {
          return d.x * 15;
        })
        .attr('r', function(d) {
          return sizeScale(+d.made + +d.missed);
        });

  circles.exit().remove();
}

function makeOverallTeamEffectShotChart(element, data, namespace, opts) {
  var width = 500;
  var height = 500;
  var svg = element;

  // NB: 3 and -3 are the theoretical max and min, but they will NEVER
  // occur except for in statistical noise. I arbitrarily chose 0.3 and -0.3 as
  // a reasonable expectation for highest actual player impact.
  var sizeScale = d3.scaleSqrt()
                    .domain([-3, -0.3, 0, 0.3, 3])
                    .range([1.5, 1.5, 0, 1.5, 1.5]);

  data.forEach(function(d) {
    d.impact = (d.on_court.frequency * d.on_court.pts_per_shot) - (d.off_court.frequency * d.off_court.pts_per_shot);
  });

  var circles = svg.selectAll('circle').data(data);

  var colorScaleDummy = d3.scaleOrdinal().domain([0, 1]).range(['#ff4136', '#28b62c'])

  if (svg.select('.legend').empty()) {
    var colorLegend = d3.legendColor()
      .scale(colorScaleDummy)
      .shape('circle')
      .shapeRadius(0.5)
      .shapePadding(0.5)
      .cells([0, 1])
      .labels([opts.labelPrefix + ' worse when on court', opts.labelPrefix + ' better when on court']);

    svg.append('g')
      .attr('class', 'legend')
      .attr("transform", "translate(0.75, 0.75)")
      .call(colorLegend);

    svg.selectAll('.legendCells .label').attr('transform', 'translate(1, 0.3)');
  }

  d3.select(".d3-tip-" + namespace).remove();

  var tip = d3.tip()
    .attr('class', 'd3-tip d3-tip-' + namespace)
    .html(function(d) {
      return 'On Court: ' + (d.on_court.frequency * d.on_court.pts_per_shot * 100).toFixed(1) + ' points per 100 shots<br>' +
             'Off Court: ' + (d.off_court.frequency * d.off_court.pts_per_shot * 100).toFixed(1) + ' points per 100 shots';
    });

  svg.call(tip);

  if (svg.select('.shot-chart-court').empty()) {
    drawCourt(svg, width, {visibleCourtLength: 35});
  }

  circles.enter()
         .append('circle')
         .merge(circles)
         .attr('transform', function(d) {
           return 'translate(' + (d.x + 25) + ', ' + (30 - d.y) + ')';
         })
         .attr('r', function(d) {
           return sizeScale(d.impact);
         })
         .attr('fill', function(d) {
           return d.impact > 0 === opts.higherIsBetter ? '#28b62c' : '#ff4136';
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

  circles.exit().remove();
}

function makeTeamAccuracyEffectShotChart(svg, namespace, data) {
  var width = 500;
  var height = 500;

  var sizeScale = d3.scaleSqrt()
                    .domain([0, d3.max(data,
                      function(d) {
                        return (d.on_court.frequency + d.off_court.frequency / 2);
                      }
                    )])
                    .range([0, 1.5]);

  var colorScale = d3.scaleLinear()
    .domain([-3, -1, 0, 1, 3])
    .range(['#5458A2', '#5458A2', '#FADC97', '#B02B48', '#B02B48']);

  if (svg.select('.legend').empty()) {
    var colorLegend = d3.legendColor()
      .scale(colorScale)
      .shape('circle')
      .shapeRadius(0.5)
      .shapePadding(0.5)
      .cells([-1, 0, 1])
      .labels(['make less when on court', 'no effect', 'make more when on court']);

    svg.append('g')
      .attr('class', 'legend')
      .attr("transform", "translate(0.75, 0.75)")
      .call(colorLegend);

    svg.selectAll('.legendCells .label').attr('transform', 'translate(1, 0.3)');
  }

  var circles = svg.selectAll('circle.shot-chart-point').data(data);

  d3.select(".d3-tip-" + namespace).remove();

  var tip = d3.tip()
    .attr('class', 'd3-tip d3-tip-' + namespace)
    .html(function(d) {
      return 'On Court: ' + d.on_court.pts_per_shot.toFixed(2) + ' PPS<br>' + 'Off Court: ' + d.off_court.pts_per_shot.toFixed(2) + ' PPS';
    });

  svg.call(tip);

  if (svg.select('.shot-chart-court').empty()) {
    drawCourt(svg, width, {visibleCourtLength: 35});
  }

  circles.enter()
    .append('circle')
    .attr('class', 'shot-chart-point')
    .attr('r', 0)
    .merge(circles)
      .on('mouseover', function(d) {
       (tip.show.bind(this))(d);
       var rect = d3.select('.d3-tip-' + namespace).node().getBoundingClientRect();
       tip.style('top', (d3.event.pageY - rect.height - 10) + 'px')
          .style('left', (d3.event.pageX - (rect.width / 2)) + 'px');
      })
      .on('mousemove', function(d) {
        var rect = d3.select('.d3-tip-' + namespace).node().getBoundingClientRect();
        tip.style('top', (d3.event.pageY - rect.height - 10) + 'px')
          .style('left', (d3.event.pageX - (rect.width / 2)) + 'px');
      })
      .on('mouseout', tip.hide)
      .attr('cx', function(d) {
        return d.x + 25;
      })
      .attr('cy', function(d) {
        return 30 - d.y;
      })
      .attr('fill', function(d) {
        return colorScale(d.pps_delta);
      })
      .transition()
        .duration(750)
        .delay(function(d) {
          return d.x * 15;
        })
        .attr('r', function(d) {
          return sizeScale(d.on_court.frequency + d.off_court.frequency / 2);
        });

  circles.exit().remove();
}

function makeTeamSelectionEffectShotChart(svg, namespace, data) {
  var width = 500;
  var height = 500;

  // NB: 3 and -3 are the theoretical max and min, but they will NEVER
  // occur except for in statistical noise. I arbitrarily chose 0.3 and -0.3 as
  // a reasonable expectation for highest actual player impact.
  var sizeScale = d3.scaleSqrt()
                    .domain([-1, -0.2, 0, 0.2, 1])
                    .range([1.5, 1.5, 0, 1.5, 1.5]);

  var circles = svg.selectAll('circle').data(data);

  var colorScaleDummy = d3.scaleOrdinal().domain([0, 1]).range(['#75caeb', '#ff851b']);

  if (svg.select('.legend').empty()) {
    var colorLegend = d3.legendColor()
      .scale(colorScaleDummy)
      .shape('circle')
      .shapeRadius(0.5)
      .shapePadding(0.5)
      .cells([0, 1])
      .labels(['less shots when on court', 'more shots when on court']);

    svg.append('g')
      .attr('class', 'legend')
      .attr("transform", "translate(0.75, 0.75)")
      .call(colorLegend);

    svg.selectAll('.legendCells .label').attr('transform', 'translate(1, 0.3)');
  }

  d3.select(".d3-tip-" + namespace).remove();

  var tip = d3.tip()
    .attr('class', 'd3-tip d3-tip-' + namespace)
    .html(function(d) {
      return 'On Court: ' + (d.on_court.frequency * 100).toFixed(1) + '% of shots<br>' +
             'Off Court: ' + (d.off_court.frequency * 100).toFixed(1) + '% of shots';
    });

  svg.call(tip);

  if (svg.select('.shot-chart-court').empty()) {
    drawCourt(svg, width, {visibleCourtLength: 35});
  }

  circles.enter()
         .append('circle')
         .merge(circles)
         .attr('transform', function(d) {
           return 'translate(' + (d.x + 25) + ', ' + (30 - d.y) + ')';
         })
         .attr('r', function(d) {
           return sizeScale(d.frequency_delta);
         })
         .attr('fill', function(d) {
           return d.frequency_delta > 0 ? '#ff851b' : '#75caeb';
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

  circles.exit().remove();
}

function makeBubbleChart(svg, namespace, data, opts) {
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

  var g;
  if (svg.select('g.chart-g').empty()) {
    g = svg.append('g')
          .attr('class', 'chart-g')
          .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')
          .attr('height', chartHeight)
          .attr('width', chartWidth);
  } else {
    g = svg.select('g.chart-g');
  }

  var xDomain;

  if (opts.xAbsolute) {
    xDomain = [opts.xMinValue, d3.max(data, function(d) { return d[opts.x]; }) + opts.xTopMargin];
  } else {
    xDomain = [
      d3.min(data, function(d) { return d[opts.x]; }) - opts.xBottomMargin,
      d3.max(data, function(d) { return d[opts.x]; }) + opts.xTopMargin
    ]
  }

  var xScale = d3.scaleLinear()
    .range([0, chartWidth])
    .domain(opts.xFlipped ? xDomain.reverse() : xDomain);

  var yScale = d3.scaleLinear()
      .range([chartHeight, 0])
      .domain([-0.1, d3.max(data, function(d) { return d[opts.y]; }) + 0.1]);

  var rScale = d3.scaleLinear()
      .domain([0, d3.max(data, function(d) { return d.made + d.missed; })])
      .range([0, 25]);

  var colorScale = d3.scaleLinear()
                     .domain([0, 0.944, 3])
                     .range(['#5458A2', '#FADC97', '#B02B48']);

  svg.selectAll('.not-reusable').remove();

  svg.append("g")
      .attr('class', 'not-reusable')
      .attr("transform", "translate(" + margin.left + "," + (chartHeight + margin.top) + ")")
      .call(
        d3.axisBottom(xScale)
          .ticks(5)
          .tickFormat(opts.tickFormat)
      );

  svg.append("g")
      .attr('class', 'not-reusable')
      .attr("transform", "translate(" + (margin.left - 30) + "," + ((chartHeight / 2) + margin.top) + ")")
      .append("text")
        .attr('transform', 'rotate(-90)')
        .attr("text-anchor", "middle")
        .text(opts.yAxis);

  svg.append("g")
      .attr('class', 'not-reusable')
      .attr("transform", "translate(" + (margin.left + (chartWidth / 2)) + "," + (chartHeight + margin.top + 30) + ")")
      .append("text")
        .attr("text-anchor", "middle")
        .text(opts.xAxis);

  svg.append("g")
      .attr('class', 'not-reusable')
      .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')
      .call(d3.axisLeft(yScale).ticks(5));

  d3.select(".d3-tip-" + namespace).remove();

  var tip = d3.tip()
    .attr('class', 'd3-tip d3-tip-' + namespace)
    .html(function(d) {
      return d.made + '/' + (d.missed + d.made);
    });

  svg.call(tip);

  var circles = g.selectAll('circle.dot').data(data, function(d) {return d[opts.x]});

  circles.enter()
    .append('circle')
    .attr('class', 'dot')
    .attr('cy', yScale(0))
    .attr('r', 0)
    .attr('fill', colorScale(0))
    .merge(circles)
    .attr('cx', function(d) {
      return xScale(d[opts.x])
    })
    .on('mouseover', function(d) {
      (tip.show.bind(this))(d);
      var rect = d3.select('.d3-tip-' + namespace).node().getBoundingClientRect();
      tip.style('top', (d3.event.pageY - rect.height - 10) + 'px')
         .style('left', (d3.event.pageX - (rect.width / 2)) + 'px');
    })
    .on('mousemove', function(d) {
      var rect = d3.select('.d3-tip-' + namespace).node().getBoundingClientRect();
      tip.style('top', (d3.event.pageY - rect.height - 10) + 'px')
         .style('left', (d3.event.pageX - (rect.width / 2)) + 'px');
    })
    .on('mouseout', tip.hide)
    .transition()
      .duration(750)
      .attr('cy', function(d) {
        return yScale(d[opts.y]);
      })
      .attr('r', function(d) {
        return rScale(d.made + d.missed);
      })
      .attr('fill', function(d) {
        return colorScale(d.pts_per_shot);
      });

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
    // We don't want to mess up our x axis with halfcourt heaves
    data = data.filter(function(d) {
      return d.distance <= 40;
    });
    makeBubbleChart(d3.select('#distance-viz'), 'distance', data, {
      x: 'distance',
      xAxis: 'Distance',
      xFlipped: true,
      xAbsolute: true,
      xMinValue: -1,
      xTopMargin: 2,
      y: 'pts_per_shot',
      yAxis: 'Points Per Shot',
      tickFormat: function(d) {
        return Math.round(d) + 'ft';
      }
    });
  });
}

function getGameTimeChart() {
  $('#gametime-viz-container').spin(true);
  $.getJSON('/players/' + gon.player_id + '/game_time_chart_data/' + gon.season, function(data) {
    $('#gametime-viz-container').spin(false);
    makeBubbleChart(d3.select('#gametime-viz'), 'gametime', data, {
      x: 'minutes',
      xAxis: 'Minutes into Game',
      xFlipped: false,
      xAbsolute: true,
      xMinValue: -2,
      xTopMargin: 2,
      y: 'pts_per_shot',
      yAxis: 'Points Per Shot',
      tickFormat: function(d) {
        return Math.round(d) + ':00';
      }
    });
  });
}

function getSeasonChart() {
  $('#over-season-viz-container').spin(true);
  $.getJSON('/players/' + gon.player_id + '/over_season_chart_data/' + gon.season, function(data) {
    data.forEach(function(x) {
      x.date = new Date(x.date).valueOf();
    });
    $('#over-season-viz-container').spin(false);
    makeBubbleChart(d3.select('#over-season-viz'), 'over-season', data, {
      x: 'date',
      xAxis: 'Date',
      xFlipped: false,
      xAbsolute: false,
      // Five days
      xBottomMargin: 86400000 * 5,
      xTopMargin: 86400000 * 5,
      y: 'pts_per_shot',
      yAxis: 'Points Per Shot',
      tickFormat: function(d) {
        return d3.timeFormat('%b %e')(new Date(d));
      }
    });
  });
}

function getTeamCharts() {
  $('#team-viz-container').spin(true);
  $.getJSON('/players/' + gon.player_id + '/team_effect_shot_chart_data/' + gon.season, function(data) {
    $('#team-viz-container').spin(false);
    makeOverallTeamEffectShotChart(
      d3.select('#team-overall-impact-viz'),
      data,
      'team-overall-impact',
      {
        higherIsBetter: true,
        labelPrefix: 'offense'
      }
    );
    makeTeamAccuracyEffectShotChart(
      d3.select('#team-accuracy-impact-viz'),
      'team-accuracy-impact',
      data
    );
    makeTeamSelectionEffectShotChart(
      d3.select('#team-selection-impact-viz'),
      'team-selection-impact',
      data
    );
  });
}

function getOpposingTeamCharts() {
  $('#opposing-team-viz-container').spin(true);
  $.getJSON('/players/' + gon.player_id + '/opposing_team_effect_shot_chart_data/' + gon.season, function(data) {
    $('#opposing-team-viz-container').spin(false);
    makeOverallTeamEffectShotChart(
      d3.select('#opposing-team-overall-impact-viz'),
      data,
      'opposing-team-overall-impact',
      {
        higherIsBetter: false,
        labelPrefix: 'defense'
      }
    );
    makeTeamAccuracyEffectShotChart(
      d3.select('#opposing-team-accuracy-impact-viz'),
      'opposing-team-accuracy-impact',
      data
    );
    makeTeamSelectionEffectShotChart(
      d3.select('#opposing-team-selection-impact-viz'),
      'opposing-team-selection-impact',
      data
    );
  });
}

function callWhenScrolledTo(callback, elem) {
  var already = false;
  $(window).scroll(checkUpdate);
  $(window).resize(checkUpdate);
  checkUpdate();

  function checkUpdate() {
    if (elem.visible(true, false, 'vertical')) {
      callback();
      $(window).unbind('scroll', checkUpdate);
      $(window).unbind('resize', checkUpdate);
    }
  }
}

function setUpSummaryStats() {
  var colorScale = d3.scaleLinear()
                     .domain([0.5, 0.944, 1.2])
                     .range(['#5458A2', '#FADC97', '#B02B48']);

  var pps = parseFloat(d3.select('#pps').text(), 10);
  d3.select('#pps')
    .style('color', colorScale(pps));

  var offensiveDelta = parseFloat(d3.select('#offensive-delta').text(), 10);
  d3.select('#offensive-delta')
    .style('color', offensiveDelta < 0 ? '#ff4136' : '#28b62c');

  var defensiveDelta = parseFloat(d3.select('#defensive-delta').text(), 10);
  d3.select('#defensive-delta')
    .style('color', defensiveDelta < 0 ? '#28b62c' : '#ff4136');
}
