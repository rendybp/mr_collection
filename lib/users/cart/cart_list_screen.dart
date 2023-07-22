import 'dart:convert';

import 'package:mr_collection/api_connection/api_connection.dart';
import 'package:mr_collection/users/controllers/cart_list_controller.dart';
import 'package:mr_collection/users/model/cart.dart';
import 'package:mr_collection/users/model/clothes.dart';
import 'package:mr_collection/users/order/order_now_screen.dart';
import 'package:mr_collection/users/userPreferences/current_user.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../item/item_details_screen.dart';


class CartListScreen extends StatefulWidget
{

  @override
  State<CartListScreen> createState() => _CartListScreenState();
}



class _CartListScreenState extends State<CartListScreen>
{
  final currentOnlineUser = Get.put(CurrentUser());
  final cartListController = Get.put(CartListController());


  getCurrentUserCartList() async
  {
    List<Cart> cartListOfCurrentUser = [];

    try
    {
      var res = await http.post(
        Uri.parse(API.getCartList),
        body:
        {
          "currentOnlineUserID": currentOnlineUser.user.user_id.toString(),
        }
      );

      if (res.statusCode == 200)
      {
        var responseBodyOfGetCurrentUserCartItems = jsonDecode(res.body);

        if (responseBodyOfGetCurrentUserCartItems['success'] == true)
        {
          (responseBodyOfGetCurrentUserCartItems['currentUserCartData'] as List).forEach((eachCurrentUserCartItemData)
          {
            cartListOfCurrentUser.add(Cart.fromJson(eachCurrentUserCartItemData));
          });
        }
        else
        {
          Fluttertoast.showToast(msg: "Keranjang Belanja Masih Kosong.");
        }

        cartListController.setList(cartListOfCurrentUser);
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
    calculateTotalAmount();
  }

  calculateTotalAmount()
  {
    cartListController.setTotal(0);

    if(cartListController.selectedItemList.length > 0)
    {
      cartListController.cartList.forEach((itemInCart)
      {
        if(cartListController.selectedItemList.contains(itemInCart.cart_id))
        {
          double eachItemTotalAmount = (itemInCart.price!) * (double.parse(itemInCart.quantity.toString()));

          cartListController.setTotal(cartListController.total + eachItemTotalAmount);
        }
      });
    }
  }

  deleteSelectedItemsFromUserCartList(int cartID) async
  {
    try
    {
      var res = await http.post(
        Uri.parse(API.deleteSelectedItemsFromCartList),
        body:
        {
          "cart_id": cartID.toString(),
        }
      );

      if(res.statusCode == 200)
      {
        var responseBodyFromDeleteCart = jsonDecode(res.body);

        if(responseBodyFromDeleteCart["success"] == true)
        {
          getCurrentUserCartList();
        }
      }
      else
      {
        Fluttertoast.showToast(msg: "Error, Status Code is not 200");
      }
    }
    catch(errorMessage)
    {
      print("Error: " + errorMessage.toString());

      Fluttertoast.showToast(msg: "Error: " + errorMessage.toString());
    }
  }

  updateQuantityInUserCart(int cartID, int newQuantity) async
  {
    try
    {
      var res = await http.post(
          Uri.parse(API.updateItemInCartList),
          body:
          {
            "cart_id": cartID.toString(),
            "quantity": newQuantity.toString(),
          }
      );

      if(res.statusCode == 200)
      {
        var responseBodyOfUpdateQuantity = jsonDecode(res.body);

        if(responseBodyOfUpdateQuantity["success"] == true)
        {
          getCurrentUserCartList();
        }
      }
      else
      {
        Fluttertoast.showToast(msg: "Error, Status Code is not 200");
      }
    }
    catch(errorMessage)
    {
      print("Error: " + errorMessage.toString());

      Fluttertoast.showToast(msg: "Error: " + errorMessage.toString());
    }
  }

  List<Map<String, dynamic>> getSelectedCartListItemsInformation()
  {
    List<Map<String, dynamic>> selectedCartListItemsInformation = [];

    if(cartListController.selectedItemList.length > 0)
    {
      cartListController.cartList.forEach((selectedCartListItem)
      {
        if(cartListController.selectedItemList.contains(selectedCartListItem.cart_id))
        {
          Map<String, dynamic> itemInformation =
          {
            "item_id": selectedCartListItem.item_id,
            "name": selectedCartListItem.name,
            'image': selectedCartListItem.image,
            'color': selectedCartListItem.color,
            'size': selectedCartListItem.size,
            'quantity': selectedCartListItem.quantity,
            'totalAmount': selectedCartListItem.price! * selectedCartListItem.quantity!,
            'price': selectedCartListItem.price!,
          };

          selectedCartListItemsInformation.add(itemInformation);
        }
      });
    }

    return selectedCartListItemsInformation;
  }

  @override
  void initState() {
    super.initState();
    getCurrentUserCartList();
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: IconThemeData(color:Colors.black),
        backgroundColor: Colors.white,
        title: const Text(
          "Keranjang Belanja",
          style: TextStyle(color: Colors.black),
        ),
        actions: [

          //to select all items
          Obx(()=>
            IconButton(
              onPressed: ()
              {
                cartListController.setIsSelectedAllItems();
                cartListController.clearAllSelectedItems();

                if(cartListController.isSelectedAll)
                {
                  cartListController.cartList.forEach((eachItem)
                  {
                    cartListController.addSelectedItem(eachItem.cart_id!);
                  });
                }

                calculateTotalAmount();
              },
              icon: Icon(
                cartListController.isSelectedAll
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                color: cartListController.isSelectedAll
                    ? Colors.black
                    : Colors.grey,
              ),
            ),
          ),

          //to delete selected item/items
          GetBuilder(
            init: CartListController(),
            builder: (c)
            {
              if(cartListController.selectedItemList.length > 0)
              {
                return IconButton(
                  onPressed: () async
                  {
                    var responseFromDialogBox = await Get.dialog(
                      AlertDialog(
                        backgroundColor: Colors.white,
                        title: const Text("Hapus"),
                        content: const Text("Anda yakin menghapus produk ini dari keranjang?"),
                        actions:
                        [
                          TextButton(
                            onPressed: ()
                            {
                              Get.back();
                            },
                            child: const Text(
                              "Tidak",
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: ()
                            {
                              Get.back(result: "yesDelete");
                            },
                            child: const Text(
                              "Ya",
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    if(responseFromDialogBox == "yesDelete")
                    {
                      cartListController.selectedItemList.forEach((selectedItemUserCartID)
                      {
                        //delete selected items now
                        deleteSelectedItemsFromUserCartList(selectedItemUserCartID);
                      });
                    }

                    calculateTotalAmount();
                  },
                  icon: const Icon(
                    Icons.delete_sweep,
                    size: 26,
                    color: Colors.redAccent,
                  ),
                );
              }
              else
              {
                return Container();
              }
            }
          ),

        ],
      ),
      body: Obx(()=>
          cartListController.cartList.length > 0
              ? ListView.builder(
                  itemCount: cartListController.cartList.length,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, index)
                  {
                    Cart cartModel = cartListController.cartList[index];

                    Clothes clothesModel = Clothes(
                      item_id: cartModel.item_id,
                      colors: cartModel.colors,
                      image: cartModel.image,
                      name: cartModel.name,
                      price: cartModel.price,
                      rating: cartModel.rating,
                      sizes: cartModel.sizes,
                      description: cartModel.description,
                      tags: cartModel.tags,
                    );

                    return SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        children: [

                          //check box
                          GetBuilder(
                            init: CartListController(),
                            builder: (c)
                            {
                              return IconButton(
                                onPressed: ()
                                {
                                  if(cartListController.selectedItemList.contains(cartModel.cart_id))
                                  {
                                    cartListController.deleteSelectedItem(cartModel.cart_id!);
                                  }
                                  else
                                  {
                                    cartListController.addSelectedItem(cartModel.cart_id!);
                                  }

                                  calculateTotalAmount();
                                },
                                icon: Icon(
                                  cartListController.selectedItemList.contains(cartModel.cart_id)
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: cartListController.isSelectedAll
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              );
                            },
                          ),

                          //name
                          //color size + price
                          //+ 2 -
                          //image
                          Expanded(
                            child: GestureDetector(
                              onTap: ()
                              {
                                Get.to(ItemDetailsScreen(itemInfo: clothesModel));
                              },
                              child: Container(
                                margin: EdgeInsets.fromLTRB(
                                  0,
                                  index == 0 ? 16 : 8,
                                  16,
                                  index == cartListController.cartList.length - 1 ? 16 : 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white,
                                  boxShadow:
                                  const [
                                    BoxShadow(
                                      offset: Offset(0, 0),
                                      blurRadius: 6,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [

                                    //name
                                    //color size + price
                                    //+ 2 -
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [

                                            //name
                                            Text(
                                              clothesModel.name.toString(),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                            const SizedBox(height: 20),

                                            //color size + price
                                            Row(
                                              children: [

                                                //color size
                                                Expanded(
                                                  child: Text(
                                                    "Color: ${cartModel.color!.replaceAll('[', '').replaceAll(']', '')}" + "\n" + "Size: ${cartModel.size!.replaceAll('[', '').replaceAll(']', '')}",
                                                    maxLines: 3,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),

                                                //price
                                                Padding(
                                                  padding: const EdgeInsets.only(
                                                      left: 12,
                                                      right: 12.0
                                                  ),
                                                  child: Text(
                                                    "\$" + clothesModel.price.toString(),
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.blueAccent,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),

                                              ],
                                            ),

                                            const SizedBox(height: 20),

                                            //+ 2 -
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [

                                                //-
                                                IconButton(
                                                  onPressed: ()
                                                  {
                                                    if(cartModel.quantity! - 1 >= 1)
                                                    {
                                                      updateQuantityInUserCart(
                                                        cartModel.cart_id!,
                                                        cartModel.quantity! - 1,
                                                      );
                                                    }
                                                  },
                                                  icon: const Icon(
                                                    Icons.remove_circle_outline,
                                                    color: Colors.grey,
                                                    size: 30,
                                                  ),
                                                ),

                                                const SizedBox(width: 10,),

                                                Text(
                                                  cartModel.quantity.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.blueAccent,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),

                                                const SizedBox(width: 7,),

                                                //+
                                                IconButton(
                                                  onPressed: ()
                                                  {
                                                    updateQuantityInUserCart(
                                                      cartModel.cart_id!,
                                                      cartModel.quantity! + 1,
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.add_circle_outline,
                                                    color: Colors.grey,
                                                    size: 30,
                                                  ),
                                                ),

                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    //item image
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(22),
                                        bottomRight: Radius.circular(22),
                                      ),
                                      child: FadeInImage(
                                        height: 185,
                                        width: 150,
                                        fit: BoxFit.cover,
                                        placeholder: const AssetImage("images/place_holder.png"),
                                        image: NetworkImage(
                                          cartModel.image!,
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

                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : const Center(
                  child: Text("Cart is Empty"),
                ),
      ),
      bottomNavigationBar: GetBuilder(
        init: CartListController(),
        builder: (c)
        {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -3),
                  color: Colors.grey,
                  blurRadius: 6,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Row(
              children: [

                //total amount
                const Text(
                  "Total Harga:",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Obx(()=>
                  Text(
                    "\$ " + cartListController.total.toStringAsFixed(2),
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const Spacer(),

                //order now btn
                Material(
                  color: cartListController.selectedItemList.length > 0
                      ? Colors.blueAccent
                      : Colors.white24,
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    onTap: ()
                    {
                      cartListController.selectedItemList.length > 0
                          ? Get.to(OrderNowScreen(
                              selectedCartListItemsInfo: getSelectedCartListItemsInformation(),
                              totalAmount: cartListController.total,
                              selectedCartIDs: cartListController.selectedItemList,
                            ))
                          : null;
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Text(
                        "Order Now",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }
}
