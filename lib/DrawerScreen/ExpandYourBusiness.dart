import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:track_loved/CustomScreen/CustomScreen.dart';

class ExpandYourBusiness extends StatefulWidget {
  const ExpandYourBusiness({super.key});

  @override
  State<ExpandYourBusiness> createState() => ExpandYourBusinessState();
}

class ExpandYourBusinessState extends State<ExpandYourBusiness> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _opportunityTitleController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _investmentController = TextEditingController();
  final TextEditingController _areaRequiredController = TextEditingController();
  final TextEditingController _returnsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _selectedOpportunityType = 'Become a Distributor';
  bool _isHindi = false;

  final List<String> _opportunityTypes = [
    'Become a Distributor',
    'Start Courier Business / Franchise',
    'Super Stockist / C&F Agency',
    'Retail Franchise Store',
    'Channel Partner / Dealership',
    'Other Business Expansion',
  ];

  @override
  void dispose() {
    _companyNameController.dispose();
    _opportunityTitleController.dispose();
    _locationController.dispose();
    _pincodeController.dispose();
    _investmentController.dispose();
    _areaRequiredController.dispose();
    _returnsController.dispose();
    _descriptionController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitOpportunity() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            _isHindi ? 'सफलता!' : 'Opportunity Published!',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Text(
            _isHindi
                ? 'आपका व्यवसाय विस्तार अवसर सफलतापूर्वक लाइव कर दिया गया है।'
                : 'Your business expansion listing has been successfully posted. Interested partners in your specified pin codes can now reach out.',
            style: TextStyle(
              fontSize: 13.5.sp,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushReplacementNamed(
                  context,
                  '/business-opportunities',
                );
              },
              child: Text(
                'View Listings',
                style: TextStyle(
                  color: const Color(0xFF0B4F4A),
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002E29),
      key: _scaffoldKey,
      drawer: AppDrawer(isHindi: _isHindi),
      appBar: AppBarScreen(
        titleEn: 'Expand Your Business',
        titleHi: 'अपना व्यवसाय बढ़ाएं',
        isHindi: _isHindi,
        notificationCount: 2,
        onLanguageChanged: (value) {
          setState(() {
            _isHindi = value;
          });
        },
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 600.w),
            padding: EdgeInsets.all(20.0.r),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: const Color(0xFF0B4F4A).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.card_membership,
                            color: const Color(0xFF0B4F4A),
                            size: 22.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              _isHindi
                                  ? 'यह एक सशुल्क सदस्यता सुविधा है, जो सीमित समय के लिए पूरी तरह से निःशुल्क उपलब्ध है।'
                                  : 'Paid Subscription Feature — Currently Available FREE for a Limited Period!',
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0B4F4A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Publish an Expansion Opportunity',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Invite verified distributors, partners, or franchisees for your business growth.',
                      style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                    ),
                    SizedBox(height: 20.h),
                    _buildSectionHeader('1. Company & Opportunity Type'),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      icon: Icons.business,
                      controller: _companyNameController,
                      label: 'Company / Brand Name *',
                      hint: 'e.g., SwiftLogistics Express / Apex Retail',
                      validatorMsg: 'Please enter your company name',
                    ),
                    SizedBox(height: 12.h),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedOpportunityType,
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      dropdownColor: const Color(0xFF141A19),
                      iconEnabledColor: Colors.white,
                      iconDisabledColor: Colors.white,
                      decoration: _inputDecoration('Opportunity Type *'),
                      items: _opportunityTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedOpportunityType = val;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      icon: Icons.title,
                      controller: _opportunityTitleController,
                      label: 'Opportunity Headline / Title *',
                      hint:
                          'e.g., Looking for City Distributors for Fast Courier Service',
                      validatorMsg: 'Please enter a headline',
                    ),
                    SizedBox(height: 20.h),
                    _buildSectionHeader('2. Target Location & Requirements'),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            icon: Icons.location_on,
                            controller: _locationController,
                            label: 'City / Region *',
                            hint: 'e.g., Faridabad / Delhi NCR',
                            validatorMsg: 'Enter city',
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            icon: Icons.pin_drop,
                            controller: _pincodeController,
                            label: 'Pin Code(s) *',
                            hint: 'e.g., 121001',
                            validatorMsg: 'Enter pin code',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            icon: Icons.currency_rupee,
                            controller: _investmentController,
                            label: 'Required Invesment *',
                            hint: 'e.g., ₹2 Lakhs - ₹5 Lakhs',
                            validatorMsg: 'Enter investment range',
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildTextField(
                            icon: Icons.square_foot,
                            controller: _areaRequiredController,
                            label: 'Space / Area Required *',
                            hint: 'e.g., 150 - 300 Sq. Ft.',
                            validatorMsg: 'Enter area details',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    _buildSectionHeader('3. Financial Returns & Proposition'),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      icon: Icons.trending_up,
                      controller: _returnsController,
                      label: 'Expected Return / Profit Margin *',
                      hint: 'e.g., 20-25% ROI or Payback within 6 Months',
                      validatorMsg: 'Please specify returns',
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      icon: Icons.description,
                      controller: _descriptionController,
                      label: 'Detailed Company & Opportunity Description *',
                      hint:
                          'Explain what you provide (training, stock, software, marketing support, etc.)',
                      validatorMsg: 'Please provide description clarity',
                      maxLines: 4,
                    ),
                    SizedBox(height: 20.h),
                    _buildSectionHeader('4. Contact Information'),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      icon: Icons.person,
                      controller: _contactPersonController,
                      label: 'Contact Person Name *',
                      hint: 'e.g., Rajesh Verma (Director)',
                      validatorMsg: 'Enter contact person name',
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            icon: Icons.phone,
                            controller: _contactPhoneController,
                            label: 'Mobile / WhatsApp Number *',
                            hint: '+91 98765 43210',
                            validatorMsg: 'Enter phone number',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildTextField(
                            controller: _emailController,
                            icon: Icons.email,
                            label: 'Business Email *',
                            hint: 'partners@company.com',
                            validatorMsg: 'Enter email address',
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B4F4A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                        ),
                        onPressed: _submitOpportunity,
                        child: Text(
                          'Publish Business Opportunity',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String validatorMsg,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.white, fontSize: 14.sp),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return validatorMsg;
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.white60, fontSize: 13.5.sp),
        hintStyle: TextStyle(fontSize: 13.sp, color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white60, size: 22.sp),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFC5A038)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white60, fontSize: 13.5.sp),
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13.sp, color: Colors.white60),
      prefixIcon: Icon(
        Icons.email_outlined,
        color: Colors.white60,
        size: 22.sp,
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFC5A038)),
      ),
    );
  }
}
