# Getting the W

> See the impact of any WNBA player.

This repository is the source code powering [the Getting the W website](http://gettingthew.com), which provides statistics and visualizations of a variety of metrics about players in [the Women's National Basketball Association](http://wnba.com).

## Background

The WNBA has a lot less publicly available data than the NBA does. The amount of analysis you can find of this data online is pretty small, although there are [some advanced statistics on the WNBA site](http://www.wnba.com/news/wnba-com-offer-advanced-statistics-every-box-score-league-history/) as well as [this highly influential blog](https://lynxdata.wordpress.com/). Notably missing is any data visualization.

I've wanted to do this project (or something like it) since I read [Sue Bird's article about the data disparity](https://www.theplayerstribune.com/sue-bird-storm-wnba-analytics/). It mostly stayed on the backburner until [Peter Beshai](https://peterbeshai.com/), creator of [Buckets](http://buckets.peterbeshai.com/), gave a guest lecture in a course I was taking. I then decided to make a first version for the 2017 season. Addition shout-out to [Austin Clemens](http://www.austinclemens.com/)' [Swish](http://www.austinclemens.com/shotcharts/) project.

## V1

For the 2017 season (or, if I'm being honest, the second half of it), I slapped together a few visualizations: a shot chart, a few bubble charts showing shooting vs. time of game, time of season, and distance, and +/- style charts showing "impact" across the court (more on those in a minute). These charts are only available at the player level, are not filterable or interactive, and are only available for the 2016 and 2017 seasons. There is no overview or index page, only a player search.

Those +/- charts are really not that advanced; they simply subtract team performance with that player off the court from team performance with that player on it. There is no adjustment for the teammates that player often plays with, which has been a major source of error for similar statistics in the past. Nevertheless, it should give a rough estimate, and is better than anything of its kind that I could find for the WNBA.

## V2

For the 2018 season, I plan to make a number of improvements to Getting the W, but I'm still not entirely sure what I will do. Feel free to get in touch or open an issue if you have suggestions or ideas!
