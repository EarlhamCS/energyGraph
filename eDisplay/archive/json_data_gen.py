#!/usr/bin/python

import sys
import gviz_api
import json
import psycopg2
import psycopg2.extras
from decimal import Decimal

def main(building_file):
    database = "energy"
    building_list = createBuildingList(building_file)
    database_conn, database_cur = connectToDatabase(database)
    all_data, dates = getAllData(database_cur,building_list)
    encodeData(all_data, dates)
    disconnectFromDatabase(database_conn, database_cur)

def createBuildingList(building_file):
    building_list = list()
    for building in building_file:
        building = building.strip("\r\n")
        building_list.append(building)
    return building_list

def connectToDatabase(database):
    try:
        database_conn = psycopg2.connect("dbname={0}".format(database))
        database_cur = database_conn.cursor(cursor_factory=
                                            psycopg2.extras.DictCursor)
        return database_conn, database_cur
    except psycopg2.OperationalError:
        print "Connection Failed!"

def getAllData(database_cur, building_list, all_data = dict()):
    max_rows = 0
    dates = list()
    for building in building_list:
        database_rows, num_rows = getBuildingData(database_cur, building)
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

def getBuildingData(database_cur, building):
    sql_query = setSQLQuery(building)
    database_cur.execute(sql_query)
    database_rows = database_cur.fetchall()
    num_entries = database_cur.rowcount
    return database_rows, num_entries

def setSQLQuery(building):
    return "select extract(epoch from date_trunc('hour',date)) as when, "\
        "round(avg(preal),1) as value from electrical_energy where area='{0}'"\
        " group by date_trunc('hour',date) order by date_trunc('hour',date)"\
        .format(building)

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
    description = dict()
    data = list()
    key_list = sorted(all_data.iterkeys())
    description["date"] = "number", "Date"
    for building in key_list:
        description[building] = "number", "some_label"
    for i in xrange(0, len(dates)):
        row = dict()
        print json.dumps(dates[i], cls=DateEncoder)
#        row["date"] = json.dumps(dates[i], cls=DateEncoder)
        for building in key_list:
            print json.dumps(all_data[building][i], cls=DecimalEncoder)
#            row[building] = json.dumps(all_data[building][i],
#                                       cls=DecimalEncoder)  # Decimal to float
        data.append(row)
    data_table = gviz_api.DataTable(description)
    data_table.LoadData(data)
    json_data = data_table.ToJSon(columns_order=description.keys())
#    json_data = data_table.ToJSon(columns_order=("date", "Barrett", "Bundy",
#                                                 "OA", "Warren", "Wilson"),
#                                  order_by="date")
    print json_data

def disconnectFromDatabase(database_conn, database_cur):
    database_cur.close()
    database_conn.close()

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return json.JSONEncoder.default(self, obj)

class DateEncoder(json.JSONEncoder):
    def default(self, obj):
        if hasattr(obj, 'isoformat'):
            return obj.isoformat()
        else:
            return str(obj)
        return json.JSONEncoder.default(self, obj)

if __name__ == '__main__':
    try:
        in_file = open("building_list.txt")
        main(in_file)
        in_file.close()
    except IOError:
        print "Missing building list file"
