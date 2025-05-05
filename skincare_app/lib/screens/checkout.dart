import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  String _paymentMethod =
      'credit_card'; // Default payment method, change as needed

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final items = cart.items;
    final total = items.entries
        .map((entry) => entry.key.price * entry.value)
        .fold(0.0, (sum, item) => sum + item);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Order Summary",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(  //Added ConstrainedBox
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3), //Set a max height
              child: ListView.separated(
                shrinkWrap: true,
                physics:
                    const ScrollPhysics(), // Use default scrolling physics
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(
                    height: 1, color: Colors.grey),
                itemBuilder: (context, index) {
                  final entry = items.entries.toList()[index];
                  final product = entry.key;
                  final quantity = entry.value;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${product.name} x $quantity",
                          style: const TextStyle(fontSize: 16)),
                      Text("\$${(product.price * quantity).toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total:",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("\$${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              "Shipping Information",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Payment Information",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                RadioListTile<String>(
                  title: const Text("Credit Card"),
                  value: 'credit_card',
                  groupValue: _paymentMethod,
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        _paymentMethod = value;
                      });
                    }
                  },
                  secondary: const Icon(Icons.credit_card), // Use secondary instead of leading
                ),
                RadioListTile<String>(
                  title: const Text("PayPal"),
                  value: 'paypal',
                  groupValue: _paymentMethod,
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        _paymentMethod = value;
                      });
                    }
                  },
                  secondary: const Icon(Icons.paypal), // Use secondary instead of leading
                ),
              ],
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Order Placed!"),
                      content: Text(
                          "Your order totaling \$${total.toStringAsFixed(2)} has been successfully placed."),
                      actions: [
                        TextButton(
                          onPressed: () {
                            cart.clear();
                            _fullNameController.clear(); // Clear full name field
                            _addressController.clear(); // Clear address field
                            _phoneNumberController.clear(); // Clear phone number field
                            Navigator.of(ctx).pop(); // Close the AlertDialog
                          },
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text("Place Order"),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

