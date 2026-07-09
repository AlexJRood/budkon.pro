import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:core/theme/icons.dart';
import '../const.dart';
import 'package:crm/invoice_pdf_generator/model/invoise_model.dart';
import 'package:get/get_utils/get_utils.dart';

 // Import your Buyer model

class BuyerSearchField extends StatefulWidget {
  final List<Buyer> buyersList;

  const BuyerSearchField({
    required this.buyersList,
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _BuyerSearchFieldState createState() => _BuyerSearchFieldState();
}

class _BuyerSearchFieldState extends State<BuyerSearchField> {
  Buyer? selectedBuyer; // To store the selected buyer
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.grey[300],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton2<Buyer>(
            iconStyleData: IconStyleData(
              icon: Padding(
                padding: const EdgeInsets.only(right: 15),
                child: AppIcons.iosArrowDown(),
              ),
            ),
            hint: Text('Select Buyer'.tr), // Hint text before selection
            value: selectedBuyer, // Currently selected buyer
            isExpanded: true, // To make sure the dropdown takes full width

            items: [
              ...widget.buyersList.map((Buyer buyer) {
                return DropdownMenuItem<Buyer>(
                  value: buyer,
                  child: Text(buyer.companyName),
                );
              }),
              DropdownMenuItem<Buyer>(
                value: null, // Special case for the "Create Buyer".tr tile
                child: Text(
                  "Can't find the buyer? Create one!".tr,
                  style:
                      TextStyle(color: Colors.blue), // Blue text for visibility
                ),
              ),
            ],
            onChanged: (Buyer? newSelectedBuyer) {
              if (newSelectedBuyer == null) {
                // User selected "Create a new buyer".tr option
                _showCreateBuyerDialog(context);
              } else {
                // A valid buyer was selected
                setState(() {
                  currentbuyer.clear();
                  selectedBuyer = newSelectedBuyer;
                  currentbuyer.add(selectedBuyer!);
                });
              }
            },
            dropdownSearchData: DropdownSearchData(
              searchController: searchController,
              searchInnerWidgetHeight: 50,
              searchInnerWidget: Container(
                height: 50,
                padding: const EdgeInsets.only(
                  top: 8,
                  bottom: 4,
                  right: 8,
                  left: 8,
                ),
                child: TextFormField(
                  cursorColor: Colors.black,
                  expands: true,
                  maxLines: null,
                  controller: searchController,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    hintText: 'Search for a buyer...'.tr,
                    hintStyle: TextStyle(fontSize: 12),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
              ),
              searchMatchFn:
                  (DropdownMenuItem<Buyer> item, String searchValue) {
                final buyer = item.value; 

                if (buyer == null) return true;


                return buyer.companyName
                        .toLowerCase()
                        .contains(searchValue.toLowerCase()) ||
                    buyer.address
                        .toLowerCase()
                        .contains(searchValue.toLowerCase()) ||
                    buyer.vatNumber
                        .toLowerCase()
                        .contains(searchValue.toLowerCase());
              },
            ),
            onMenuStateChange: (isOpen) {
              if (!isOpen) {
                searchController.clear();
              }
            },
          ),
        ),
      ),
    );
  }


  void _showCreateBuyerDialog(BuildContext context) {
    var companyName = '';
    var address = '';
    var vatNumber = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create New Buyer'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Company Name'.tr),
                onChanged: (value) => companyName = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Address'.tr),
                onChanged: (value) => address = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'VAT Number'.tr),
                onChanged: (value) => vatNumber = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog without action
              },
              child: Text('Cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () {
                if (companyName.isNotEmpty &&
                    address.isNotEmpty &&
                    vatNumber.isNotEmpty) {
                  // Check if the buyer already exists
                  bool buyerExists = widget.buyersList.any((buyer) =>
                      buyer.companyName.toLowerCase() ==
                      companyName.toLowerCase());

                  if (!buyerExists) {
                    Buyer newBuyer = Buyer(
                      companyName: companyName,
                      address: address,
                      vatNumber: vatNumber,
                    );
                    setState(() {
                      // Add the newly created buyer to the list
                      widget.buyersList.add(newBuyer);
                      selectedBuyer = newBuyer;
                      currentbuyer.clear();
                      currentbuyer.add(selectedBuyer!);
                    });

                    Navigator.of(context).pop(); // Close dialog
                  } else {
                    // Show a message if the buyer already exists
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Buyer with this name already exists!'.tr),
                      ),
                    );
                  }
                }
              },
              child: Text('Create'.tr),
            ),
          ],
        );
      },
    );
  }
}
