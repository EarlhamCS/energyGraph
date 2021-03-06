#!/usr/bin/python

import gviz_api
import datetime
import psycopg2
import psycopg2.extras
try:
    import simplejson as json
except ImportError:
    import json


def main(table, building_list, json_file):
    database = "energy"
    database_conn, database_cur = connectToDatabase(database)
    all_data, dates = getAllData(database_cur,building_list, table)
    json_data = encodeData(all_data, dates)
    json_file.write(json_data)
    disconnectFromDatabase(database_conn, database_cur)

def getAllData(database_cur, building_list, table, all_data = dict()):
    max_rows = 0
    dates = list()
    for building in building_list:
        database_rows, num_rows = getBuildingData(database_cur, building, table)
        overwrite_dates, dates, max_rows = selectDates(num_rows, max_rows, 
                                                       dates)
        building_data = list()
        for row in database_rows:
            if overwrite_dates:
                dates.append(row["when"])
            building_data.append(row["value"])
        all_data[building] = building_data
    all_data = equalizeDataValues(all_data, max_rows)
    return all_data, dates

def getBuildingData(database_cur, building, table):
    sql_query = setSQLQuery(building, table)
    database_cur.execute(sql_query)
    database_rows = database_cur.fetchall()
    num_entries = database_cur.rowcount
    return database_rows, num_entries

def setSQLQuery(building, table):
    if (building == " total"):
    	return "select extract(epoch from date_trunc('hour',date)) as when, "\
        	"round(avg(preal),1) as value from " + table + " where area='%s'"\
        	" group by date_trunc('hour',date) order by date_trunc('hour',date)"\
        	% ("total")
    else:
   		return "select extract(epoch from date_trunc('hour',date)) as when, "\
        	"round(avg(preal),1) as value from " + table + " where area='%s'"\
        	" group by date_trunc('hour',date) order by date_trunc('hour',date)"\
        	% (building)

def selectDates(num_rows, max_rows, dates):
    if num_rows >= max_rows:
        max_rows = num_rows
        overwrite_dates = True
        dates = list()
    else:
        overwrite_dates = False
    return overwrite_dates, dates, max_rows

def equalizeDataValues(all_data, end):
    for building in all_data.keys():
        beg = len(all_data[building])
        for i in xrange(beg, end+1):  # Make range inclusive
            all_data[building].insert(0,None)
    return all_data

def encodeData(all_data, dates):
    description = list()
    data = list()
    gviz_column_headers = ("date",)
    key_list = sorted(all_data.iterkeys())
    description.append(("date", "datetime"))
    for building in key_list:
        gviz_column_headers += (building,)
        description.append(("%s" % (building), "number"))
    for i in xrange(0, len(dates)):
        row = list()
        row.append(toDateTime(float(dates[i])))  # String to datetime
        for building in key_list:
            row.append((toFloat(all_data[building][i]),
                        "%s" % (all_data[building][i])+" kW"))  # Decimal to float
        data.append(row)
    data_table = gviz_api.DataTable(description)
    data_table.LoadData(data)
    json_data = data_table.ToJSon(columns_order=(gviz_column_headers),
                                  order_by="date")
    return json_data

def toFloat(obj):
    if obj == None:
        return None
    else:
        return float(str(obj))

def toDateTime(obj):
	return datetime.datetime.fromtimestamp(obj)

def connectToDatabase(database):
    try:
        database_conn = psycopg2.connect("dbname=%s" % (database))
        database_cur = database_conn.cursor(cursor_factory=
                                            psycopg2.extras.DictCursor)
        return database_conn, database_cur
    except psycopg2.OperationalError:
        print "Connection Failed!"

def disconnectFromDatabase(database_conn, database_cur):
    database_cur.close()
    database_conn.close()

if __name__ == '__main__':
    try:
	displayDir = "/home/energy/public_html/production/eDisplay/"
	minimalList = ["Warren", "Wilson", "Barrett", "Bundy", "OA", "Mills", "Hoerner"]
	for table, fname, buildingList in [ ( "normed_electrical_energy", "line_chart.txt", minimalList), ("electrical_energy", "raw_line_chart.txt", minimalList + ["total"] ) ]:
		out_file = open(displayDir + fname,'w')
		main(table, buildingList, out_file)
		out_file.close()
    except IOError:
        print "Error opening files"
