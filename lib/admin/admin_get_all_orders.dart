import 'dart:convert';

import 'package:mr_collection/users/model/order.dart';
import 'package:mr_collection/users/order/order_details.dart';
import 'package:mr_collection/users/userPreferences/current_user.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../api_connection/api_connection.dart';


class AdminGetAllOrdersScreen extends StatelessWidget
{
  final currentOnlineUser = Get.put(CurrentUser());


  Future<List<Order>> getAllOrdersList() async
  {
    List<Order> ordersList = [];

    try
    {
      var res = await http.post(
          Uri.parse(API.adminGetAllOrders),
          body:
          {

          }
      );

      if (res.statusCode == 200)
      {
        var responseBodyOfCurrentUserOrdersList = jsonDecode(res.body);

        if (responseBodyOfCurrentUserOrdersList['success'] == true)
        {
          (responseBodyOfCurrentUserOrdersList['allOrdersData'] as List).forEach((eachOrderData)
          {
            ordersList.add(Order.fromJson(eachOrderData));
          });
        }
      }
      else
      {
        Fluttertoast.showToast(msg: "Status Code is not 200");
      }
    }
    catch(errorMsg)
    {
      Fluttertoast.showToast(msg: "Error:: " + errorMsg.toString());
    }

    return ordersList;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          //Order image       //history image
          //myOrder title     //history title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                //order icon image
                // my orders
                Column(
                  children: [
                    Image.asset(
                      "images/orders_icon.png",
                      width: 140,
                    ),
                    const Text(
                      "Pesanan Masuk",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    //some info
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30.0),
                      child: Text(
                        "Berikut ini pesanan yang masuk.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          //displaying the user orderList
          Expanded(
            child: displayOrdersList(context),
          ),

        ],
      ),
    );
  }

  Widget displayOrdersList(context)
  {
    return FutureBuilder(
      future: getAllOrdersList(),
      builder: (context, AsyncSnapshot<List<Order>> dataSnapshot)
      {
        if(dataSnapshot.connectionState == ConnectionState.waiting)
        {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Center(
                child: Text(
                  "Connection Waiting...",
                  style: TextStyle(color: Colors.grey,),
                ),
              ),
              Center(
                child: CircularProgressIndicator(),
              ),
            ],
          );
        }
        if(dataSnapshot.data == null)
        {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Center(
                child: Text(
                  "Tidak ditemukan pesanan...",
                  style: TextStyle(color: Colors.grey,),
                ),
              ),
              Center(
                child: CircularProgressIndicator(),
              ),
            ],
          );
        }
        if(dataSnapshot.data!.length > 0)
        {
          List<Order> orderList = dataSnapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (context, index)
            {
              return const Divider(
                height: 1,
                thickness: 1,
              );
            },
            itemCount: orderList.length,
            itemBuilder: (context, index)
            {
              Order eachOrderData = orderList[index];

              return Card(
                color: Colors.white30,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: ListTile(
                    onTap: ()
                    {
                      Get.to(OrderDetailsScreen(
                        clickedOrderInfo: eachOrderData,
                      ));
                    },
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order ID # " + eachOrderData.order_id.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Total: \nRp. " + eachOrderData.totalAmount!.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        //date
                        //time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            //date
                            Text(
                              DateFormat(
                                  "dd MMMM, yyyy"
                              ).format(eachOrderData.dateTime!),
                              style: const TextStyle(
                                color: Colors.black,
                              ),
                            ),

                            const SizedBox(height: 4),

                            //time
                            Text(
                              DateFormat(
                                  "hh:mm a"
                              ).format(eachOrderData.dateTime!),
                              style: const TextStyle(
                                color: Colors.black,
                              ),
                            ),

                          ],
                        ),

                        const SizedBox(width: 6),

                        const Icon(
                          Icons.navigate_next,
                          color: Colors.blueAccent,
                        ),

                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
        else
        {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Center(
                child: Text(
                  "Tidak ada yang bisa ditampilkan...",
                  style: TextStyle(color: Colors.grey,),
                ),
              ),
              Center(
                child: CircularProgressIndicator(),
              ),
            ],
          );
        }
      },
    );
  }
}
