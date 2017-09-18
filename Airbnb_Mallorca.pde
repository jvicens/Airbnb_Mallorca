import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.unfolding.geo.Location;
import de.fhpotsdam.unfolding.marker.SimplePointMarker;
import de.fhpotsdam.unfolding.data.GeoJSONReader;
import de.fhpotsdam.unfolding.data.Feature;
import de.fhpotsdam.unfolding.providers.AbstractMapProvider;
import de.fhpotsdam.unfolding.providers.OpenStreetMap;
import de.fhpotsdam.unfolding.providers.StamenMapProvider;

import java.util.List;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.text.DateFormat;
import java.text.SimpleDateFormat;

import processing.core.*;

UnfoldingMap map;
AirbnbMarker airbnbMarker;
AirbnbObject airbnbObject;
ArrayList<AirbnbObject> airbnbObjectList_WithReview =  new ArrayList<AirbnbObject>();
ArrayList<AirbnbObject> airbnbObjectList_WithoutReview =  new ArrayList<AirbnbObject>();

int[] countsFirstReview = {
  0
};
int last_month = 7; // last month
int index_counts_first_review = 0;

long current_time = 1310680800; // initial time
long one_day = 24*60*60; // time of one day
long last_time = 0;

long time_refresh = 0; // time refresh screen

int index = 0;
int index_add = 0;

Table table;

void setup() {
  size(1000, 800);

  map = new UnfoldingMap(this, new StamenMapProvider.TonerBackground());
  map.zoomTo(10);
  map.panTo(new Location(39.6, 2.9));
  MapUtils.createDefaultEventDispatcher(this, map);

  table = loadTable("data_processing.csv", "header");

  println(table.getRowCount() + " total rows in table"); 

  for (TableRow row : table.rows ()) {
    airbnbObject = new AirbnbObject();
    airbnbObject.id = row.getInt("id");
    airbnbObject.location = new Location(row.getFloat("latitude"), row.getFloat("longitude"));
    airbnbObject.first_review = row.getInt("first_review");
    //println(" " + airbnbObject.location + " has an ID of " + airbnbObject.id + " and " + airbnbObject.first_review);

    //airbnbMarker = new AirbnbMarker(airbnbObject.location);
    if (airbnbObject.first_review != 0) {
      airbnbObjectList_WithReview.add(airbnbObject);
    } else {
      airbnbObjectList_WithoutReview.add(airbnbObject);
    }
  }

  Collections.sort(airbnbObjectList_WithReview, new Comparator<AirbnbObject>() {
    @Override
      public int compare(AirbnbObject airbnbObject2, AirbnbObject airbnbObject1) {
      int cmp = airbnbObject2.first_review > airbnbObject1.first_review ? +1 : airbnbObject2.first_review < airbnbObject1.first_review ? -1 : 0;
      return  cmp;
    }
  }
  );
}

void draw() {
  map.draw();
  fill(255);
  textSize(18);
  text(dateWithFormat(current_time, "dd/MM/yyyy"), 50, 50);

  if ( millis() - time_refresh >= 10) {
    doRefresh();
    time_refresh = millis();
  }
  pdfFirstReview(countsFirstReview, index_counts_first_review);
}

void pdfFirstReview(int[] counts, int current_index) {
  for (int i=0; i <counts.length; i=i+1) {
    if (current_index == i) {
      fill(200, 10, 0, 200);
    } else {
      fill(255,200);
    }
    rect(30 + (i*12), 750, 12, -(counts[i]/3));
  }
}

void drawFirstReview() {

  map.getDefaultMarkerManager().clearMarkers();
  index = 0;
  airbnbObject = airbnbObjectList_WithReview.get(index);

  while (airbnbObject.first_review <= current_time) {
    airbnbMarker = new AirbnbMarker(airbnbObject.location);

    if (airbnbObject.first_review <= current_time - one_day*4) {
      airbnbMarker.scale = 5;
      map.addMarker(airbnbMarker);
    } else if (airbnbObject.first_review <= current_time - one_day*3) {
      airbnbMarker.scale = 4;
      map.addMarker(airbnbMarker);
    } else if (airbnbObject.first_review <= current_time - one_day*2) {
      airbnbMarker.scale = 3;
      map.addMarker(airbnbMarker);
    } else if (airbnbObject.first_review <= current_time - one_day) {
      airbnbMarker.scale = 2;
      map.addMarker(airbnbMarker);
    } else if (airbnbObject.first_review > current_time - one_day) {
      airbnbMarker.scale = 1;
      map.addMarker(airbnbMarker);
      if (int(dateWithFormat(airbnbObject.first_review, "MM")) == last_month) {
        countsFirstReview[index_counts_first_review] = countsFirstReview[index_counts_first_review] + 1;
      } else {
        println(countsFirstReview);
        last_month = int(dateWithFormat(airbnbObject.first_review, "MM"));
        index_counts_first_review = index_counts_first_review + 1;
        countsFirstReview = append(countsFirstReview, 1);
        
      }
    }
    index = index + 1;
    if (index < airbnbObjectList_WithReview.size()) {
      airbnbObject = airbnbObjectList_WithReview.get(index);
    }
  }
  current_time = current_time + one_day;
}


void doRefresh() {
  drawFirstReview();
}


void keyPressed() {
  drawFirstReview();
}

public class AirbnbMarker extends SimplePointMarker {

  public float scale =  1;

  public AirbnbMarker(Location location) {
    super(location);
  }

  public void draw(PGraphics pg, float x, float y) {
    pg.pushStyle();
    pg.noStroke();
    pg.fill(200, 10, 0, 200);
    pg.ellipse(x, y, 50/scale, 50/scale);
    pg.fill(255, 100);
    pg.ellipse(x, y, 40/scale, 40/scale);
    pg.popStyle();
  }
}

private class AirbnbObject {
  int id;
  Location location;
  long first_review;
  long last_review;
  int avaliability;
  int host_listings_count;
} 

String dateWithFormat(long time, String format) {
  Date d = new Date(time*1000);  
  DateFormat df = new SimpleDateFormat(format);
  return df.format(d);
}

