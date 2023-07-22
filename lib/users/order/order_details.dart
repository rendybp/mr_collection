import 'dart:convert';

import 'package:mr_collection/api_connection/api_connection.dart';
import 'package:mr_collection/users/model/order.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;


class OrderDetailsScreen extends StatefulWidget
{
  final Order? clickedOrderInfo;

  OrderDetailsScreen({this.clickedOrderInfo,});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}



class _OrderDetailsScreenState extends State<OrderDetailsScreen>
{
  RxString _status = "new".obs;
  String get status => _status.value;

  updateParcelStatusForUI(String parcelReceived)
  {
    _status.value = parcelReceived;
  }

  showDialogForParcelConfirmation() async
  {
    if(widget.clickedOrderInfo!.status == "new")
    {
      var response = await Get.dialog(
        AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            "Konfirmasi",
            style: TextStyle(
              color: Colors.black,
            ),
          ),
          content: const Text(
            "Apakah anda sudah menerima paket?",
            style: TextStyle(
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: ()
              {
                Get.back();
              },
              child: const Text(
                "Tidak",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            TextButton(
              onPressed: ()
              {
                Get.back(result: "yesConfirmed");
              },
              child: const Text(
                "Ya",
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      );

      if(response == "yesConfirmed")
      {
        updateStatusValueInDatabase();
      }
    }
  }

  updateStatusValueInDatabase() async
  {
    try
    {
      var response = await http.post(
        Uri.parse(API.updateStatus),
        body:
        {
          "order_id": widget.clickedOrderInfo!.order_id.toString(),
        }
      );

      if(response.statusCode == 200)
      {
        var responseBodyOfUpdateStatus = jsonDecode(response.body);

        if(responseBodyOfUpdateStatus["success"] == true)
        {
          updateParcelStatusForUI("arrived");
        }
      }
    }
    catch(e)
    {
      print(e.toString());
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    updateParcelStatusForUI(widget.clickedOrderInfo!.status.toString());
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: IconThemeData(color:Colors.black),
        backgroundColor: Colors.white,
        title: Text(
          DateFormat("dd MMMM, yyyy - hh:mm a").format(widget.clickedOrderInfo!.dateTime!),
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Material(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: ()
                {
                  if(status == "new")
                  {
                    showDialogForParcelConfirmation();
                  }
                },
                borderRadius: BorderRadius.circular(30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Text(
                        "Diterima",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8,),
                      Obx(()=>
                          status == "new"
                              ? const Icon(Icons.help_outline, color: Colors.redAccent,)
                              : const Icon(Icons.check_circle_outline, color: Colors.greenAccent,)
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              //display items belongs to clicked order
              displayClickedOrderItems(),

              const SizedBox(height: 16,),

              //phoneNumber
              showTitleText("Nomor Telepon:"),
              const SizedBox(height: 8,),
              showContentText(widget.clickedOrderInfo!.phoneNumber!),

              const SizedBox(height: 26,),

              //Shipment Address
              showTitleText("Alamat Pengiriman:"),
              const SizedBox(height: 8,),
              showContentText(widget.clickedOrderInfo!.shipmentAddress!),

              const SizedBox(height: 26,),

              //delivery
              showTitleText("Jasa Ekspedisi:"),
              const SizedBox(height: 8,),
              showContentText(widget.clickedOrderInfo!.deliverySystem!),

              const SizedBox(height: 26,),

              //payment
              showTitleText("Metode Pembayaran:"),
              const SizedBox(height: 8,),
              showContentText(widget.clickedOrderInfo!.paymentSystem!),

              const SizedBox(height: 26,),

              //note
              showTitleText("Catatan:"),
              const SizedBox(height: 8,),
              showContentText(widget.clickedOrderInfo!.note!),

              const SizedBox(height: 26,),

              //total amount
              showTitleText("Total Bayar:"),
              const SizedBox(height: 8,),
              showContentText(widget.clickedOrderInfo!.totalAmount!.toStringAsFixed(0)),

              const SizedBox(height: 26,),

              //payment proof
              showTitleText("Bukti Pembayaran:"),
              const SizedBox(height: 8,),
              FadeInImage(
                width: MediaQuery.of(context).size.width * 0.8,
                fit: BoxFit.fitWidth,
                placeholder: const AssetImage("images/place_holder.png"),
                image: NetworkImage(
                  API.hostImages + widget.clickedOrderInfo!.image!,
                ),
                imageErrorBuilder: (context, error, stackTraceError)
                {
                  return const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                    ),
                  );
                },
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget showTitleText(String titleText)
  {
    return Text(
      titleText,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: Colors.black,
      ),
    );
  }

  Widget showContentText(String contentText)
  {
    return Text(
      contentText,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black45,
      ),
    );
  }

  Widget displayClickedOrderItems()
  {
    List<String> clickedOrderItemsInfo = widget.clickedOrderInfo!.selectedItems!.split("||");

    return Column(
      children: List.generate(clickedOrderItemsInfo.length, (index)
      {
        Map<String, dynamic> itemInfo = jsonDecode(clickedOrderItemsInfo[index]);

        return Container(
          margin: EdgeInsets.fromLTRB(
            16,
            index == 0 ? 16 : 8,
            16,
            index == clickedOrderItemsInfo.length - 1 ? 16 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow:
            const [
              BoxShadow(
                offset: Offset(0, 0),
                blurRadius: 6,
                color: Colors.black26,
              ),
            ],
          ),
          child: Row(
            children: [

              //image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: FadeInImage(
                  height: 150,
                  width: 130,
                  fit: BoxFit.cover,
                  placeholder: const AssetImage("images/place_holder.png"),
                  image: NetworkImage(
                    itemInfo["image"],
                  ),
                  imageErrorBuilder: (context, error, stackTraceError)
                  {
                    return const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                      ),
                    );
                  },
                ),
              ),

              //name
              //size
              //price
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      //name
                      Text(
                        itemInfo["name"],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      //size + color
                      Text(
                        itemInfo["size"].replaceAll("[", "").replaceAll("]", "") + "\n" + itemInfo["color"].replaceAll("[", "").replaceAll("]", ""),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 16),

                      //price
                      Text(
                        "Rp. " + itemInfo["totalAmount"]!.toStringAsFixed(0),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        itemInfo["price"]!.toStringAsFixed(0) + " x "
                            + itemInfo["quantity"].toString()
                            + " = " + itemInfo["totalAmount"]!.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),


                    ],
                  ),
                ),
              ),

              //quantity
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Q: " + itemInfo["quantity"].toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.blueAccent,
                  ),
                ),
              ),


            ],
          ),
        );
      }),
    );
  }
}
