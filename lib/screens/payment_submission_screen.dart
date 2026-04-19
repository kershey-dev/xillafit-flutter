import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xillafit_flutter/core/config/app_links.dart';
import 'package:xillafit_flutter/core/payments/payment_session_store.dart';
import 'package:xillafit_flutter/features/auth/data/bulacan_locations.dart';
import 'package:xillafit_flutter/features/auth/presentation/auth_providers.dart';
import 'package:xillafit_flutter/features/cart/presentation/cart_provider.dart';
import 'package:xillafit_flutter/features/catalog/data/clothing_item_model.dart';
import 'package:xillafit_flutter/features/checkout/data/checkout_repository.dart';
import 'package:xillafit_flutter/features/profile/presentation/profile_providers.dart';
import 'package:xillafit_flutter/screens/mobile_webview_screen.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/common/app_card.dart';
import 'package:xillafit_flutter/widgets/common/primary_button.dart';

enum _PaymentType { deposit, full }

enum _DeliveryOption { delivery, pickup }

class PaymentSubmissionArgs {
  const PaymentSubmissionArgs({
    this.directItems,
    this.customDesign,
  });

  final List<CheckoutLineItem>? directItems;
  final CustomDesignDraft? customDesign;

  factory PaymentSubmissionArgs.singleItem({
    required ClothingItemModel item,
    required int quantity,
    String? size,
    String? fabric,
    String? customName,
    String? customNumber,
  }) {
    return PaymentSubmissionArgs(
      directItems: [
        CheckoutLineItem(
          id: item.id,
          name: item.name,
          price: item.basePrice ?? 0,
          quantity: quantity,
          image: item.previewImageUrl,
          category: item.description,
          size: size,
          fabric: fabric,
          customName: customName,
          customNumber: customNumber,
        ),
      ],
    );
  }

  factory PaymentSubmissionArgs.customDesign({
    required CustomDesignDraft design,
  }) {
    return PaymentSubmissionArgs(customDesign: design);
  }
}

class PaymentSubmissionScreen extends ConsumerStatefulWidget {
  static const routeName = '/payment-submission';

  const PaymentSubmissionScreen({super.key});

  @override
  ConsumerState<PaymentSubmissionScreen> createState() => _PaymentSubmissionScreenState();
}

class _PaymentSubmissionScreenState extends ConsumerState<PaymentSubmissionScreen> {
  _PaymentType _paymentType = _PaymentType.deposit;
  _DeliveryOption _deliveryOption = _DeliveryOption.delivery;
  bool _loading = true;
  bool _submitting = false;
  bool _waitingForPaymentReturn = false;
  String? _error;
  String? _estimateDate;
  List<DeliveryZone> _zones = const [];
  final Map<String, int> _customQuantities = {
    '5XS': 0,
    '4XS': 0,
    '3XS': 0,
    '2XS': 0,
    'XS': 0,
    'S': 0,
    'M': 0,
    'L': 0,
    'XL': 0,
    '2XL': 0,
    '3XL': 0,
  };
  final _customInstructionsController = TextEditingController();
  final _customFabricOptions = const [
    'Cotton 100%',
    'Poly-Cotton Blend',
    'Dri-Fit Polyester',
    'Premium CVC',
    'Fleece (hoodie)',
  ];
  String _customFabric = 'Cotton 100%';
  bool _didPrefillCustomDesign = false;

  final _streetController = TextEditingController();
  String _selectedMunicipality = '';
  String _selectedBarangay = '';
  String _zipCode = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefillCustomDesign) return;

    final design = _screenArgs()?.customDesign;
    if (design == null) return;

    _didPrefillCustomDesign = true;
    _customFabric = design.fabric?.trim().isNotEmpty == true
        ? design.fabric!.trim()
        : _customFabric;
    if ((design.instructions ?? '').trim().isNotEmpty) {
      _customInstructionsController.text = design.instructions!.trim();
    }
    if (design.quantities.isNotEmpty) {
      for (final size in _customQuantities.keys) {
        _customQuantities[size] = design.quantities[size] ?? 0;
      }
    } else if ((design.totalPieces ?? 0) > 0) {
      final fallbackSize = (design.sizeLabel ?? '').trim();
      final bucket = _customQuantities.containsKey(fallbackSize)
          ? fallbackSize
          : 'M';
      _customQuantities[bucket] = design.totalPieces!;
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _customInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(checkoutRepositoryProvider);
      final results = await Future.wait<dynamic>([
        repo.fetchDeliveryZones(),
        repo.fetchEstimatedCompletionDate(),
      ]);

      final profile = ref.read(currentProfileProvider).asData?.value;
      _prefillAddress(profile);

      if (!mounted) return;
      setState(() {
        _zones = results[0] as List<DeliveryZone>;
        _estimateDate = results[1] as String?;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _prefillAddress(dynamic profile) {
    final p = profile;
    if (p == null) return;
    _streetController.text = p.streetAddress?.toString() ?? '';
    final municipality = _municipalityByName(p.municipality?.toString() ?? '');
    final barangay = p.barangay?.toString() ?? '';

    _selectedMunicipality = municipality?.name ?? '';
    _selectedBarangay = municipality?.barangays.contains(barangay) == true ? barangay : '';
    _zipCode = municipality?.zipCode ?? (p.zipCode?.toString() ?? '');
  }

  BulacanMunicipality? _municipalityByName(String value) {
    for (final municipality in bulacanMunicipalities) {
      if (municipality.name == value) return municipality;
    }
    return null;
  }

  List<CheckoutLineItem> _resolveItems() {
    final args = ModalRoute.of(context)?.settings.arguments;
    final directItems = args is PaymentSubmissionArgs ? args.directItems : null;
    if (directItems != null && directItems.isNotEmpty) {
      return directItems;
    }

    return [
      for (final line in ref.read(cartProvider).items)
        CheckoutLineItem.fromCartLine(line),
    ];
  }

  PaymentSubmissionArgs? _screenArgs() {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is PaymentSubmissionArgs ? args : null;
  }

  CustomDesignDraft? _customDesign() {
    return _screenArgs()?.customDesign;
  }

  bool get _isCustomDesignFlow => _customDesign() != null;

  bool get _hasPrefilledBulkConfiguration {
    final design = _customDesign();
    if (design == null) return false;
    return design.roster.isNotEmpty ||
        design.quantities.isNotEmpty ||
        (design.totalPieces ?? 0) > 0 ||
        (design.sizeLabel ?? '').trim().isNotEmpty ||
        (design.fabric ?? '').trim().isNotEmpty ||
        design.unitPrice != null ||
        design.totalPrice != null;
  }

  int get _customTotalPieces {
    return _customQuantities.values.fold<int>(0, (sum, qty) => sum + qty);
  }

  void _changeCustomQuantity(String size, int delta) {
    setState(() {
      final current = _customQuantities[size] ?? 0;
      _customQuantities[size] = (current + delta).clamp(0, 999);
    });
  }

  double _deliveryFeeFor(String municipality) {
    if (_deliveryOption == _DeliveryOption.pickup) return 0;
    for (final zone in _zones) {
      if (zone.zoneName.toLowerCase() == municipality.toLowerCase()) {
        return zone.baseFee;
      }
    }
    return 100;
  }

  Future<void> _submitCheckout(List<CheckoutLineItem> items) async {
    if (_isCustomDesignFlow) {
      await _submitCustomCheckout();
      return;
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your checkout is empty.')),
      );
      return;
    }

    if (_deliveryOption == _DeliveryOption.delivery) {
      if (_streetController.text.trim().isEmpty ||
          _selectedMunicipality.isEmpty ||
          _selectedBarangay.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete your delivery address first.')),
        );
        return;
      }
    }

    final session = ref.read(authSessionProvider).asData?.value;
    final profile = ref.read(currentProfileProvider).asData?.value;
    final user = session?.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again.')),
      );
      return;
    }

    final itemsTotal = items.fold<double>(0, (sum, item) => sum + item.subtotal);
    final deliveryFee = _deliveryFeeFor(_selectedMunicipality);
    final grandTotal = itemsTotal + deliveryFee;
    final amountDueNow = _paymentType == _PaymentType.full ? grandTotal : grandTotal * 0.5;
    final referenceId = 'XF-PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final checkoutCity =
        _deliveryOption == _DeliveryOption.pickup ? 'Marilao' : _selectedMunicipality;
    final checkoutZipCode =
        _deliveryOption == _DeliveryOption.pickup ? '3019' : _zipCode;
    final checkoutStreet = _deliveryOption == _DeliveryOption.pickup
        ? '3620 MacArthur Hwy, Marilao, Bulacan'
        : _streetController.text.trim();

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await ref.read(checkoutRepositoryProvider).createCheckoutSession(
            amountDueNow: amountDueNow,
            isDeposit: _paymentType == _PaymentType.deposit,
            referenceId: referenceId,
            items: items,
            profileId: user.id,
            successUrl: AppLinks.paymentCallbackUrl(
              success: true,
              flow: 'checkout',
              referenceId: referenceId,
            ),
            cancelUrl: AppLinks.paymentCallbackUrl(
              success: false,
              flow: 'checkout',
              referenceId: referenceId,
            ),
            deliveryOption: _deliveryOption == _DeliveryOption.delivery ? 'delivery' : 'pickup',
            deliveryAddress: _deliveryOption == _DeliveryOption.delivery
                ? '${_streetController.text.trim()}, $_selectedBarangay, $_selectedMunicipality, Bulacan $_zipCode'
                : 'Pick up at Bulacan Hub (3620 MacArthur Hwy, Marilao, Bulacan)',
            deliveryFee: deliveryFee,
            billingName: (profile?.fullName ?? user.userMetadata?['full_name']?.toString() ?? 'Guest User').trim(),
            billingEmail: (profile?.email ?? user.email ?? '').trim(),
            billingPhone: _normalizePhone(profile?.contactNumber?.toString()),
            city: checkoutCity,
            postalCode: checkoutZipCode,
            streetAddress: checkoutStreet,
          );

      if ((result.sessionId ?? '').trim().isNotEmpty) {
        await PaymentSessionStore.save(
          PendingPaymentSession(
            sessionId: result.sessionId!,
            flow: 'checkout',
            referenceId: referenceId,
          ),
        );
      }

      if (!mounted) return;
      setState(() => _waitingForPaymentReturn = true);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MobileWebViewScreen(
            title: 'Secure Checkout',
            initialUrl: result.checkoutUrl,
            mode: MobileWebViewMode.payment,
          ),
        ),
      );
    } catch (error) {
      await PaymentSessionStore.clear();
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _waitingForPaymentReturn = false;
        });
      }
    }
  }

  Future<void> _submitCustomCheckout() async {
    final design = _customDesign();
    if (design == null) return;

    if (_customTotalPieces <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one size quantity for your custom design.')),
      );
      return;
    }

    if (_deliveryOption == _DeliveryOption.delivery) {
      if (_streetController.text.trim().isEmpty ||
          _selectedMunicipality.isEmpty ||
          _selectedBarangay.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete your delivery address first.')),
        );
        return;
      }
    }

    final session = ref.read(authSessionProvider).asData?.value;
    final profile = ref.read(currentProfileProvider).asData?.value;
    final user = session?.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again.')),
      );
      return;
    }

    final deliveryFee = _deliveryFeeFor(_selectedMunicipality);
    final unitPrice = design.unitPrice ?? 350.0;
    final itemsTotal = _customTotalPieces * unitPrice;
    final grandTotal = itemsTotal + deliveryFee;
    final amountDueNow = grandTotal * 0.5;
    final referenceId = 'XF-CUSTOM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final checkoutCity =
        _deliveryOption == _DeliveryOption.pickup ? 'Marilao' : _selectedMunicipality;
    final checkoutZipCode =
        _deliveryOption == _DeliveryOption.pickup ? '3019' : _zipCode;
    final checkoutStreet = _deliveryOption == _DeliveryOption.pickup
        ? '3620 MacArthur Hwy, Marilao, Bulacan'
        : _streetController.text.trim();
    DeliveryZone? selectedZone;
    for (final zone in _zones) {
      if (zone.zoneName.toLowerCase() == _selectedMunicipality.toLowerCase()) {
        selectedZone = zone;
        break;
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await ref.read(checkoutRepositoryProvider).createCustomCheckoutSession(
            design: design,
            profileId: user.id,
            quantities: {
              for (final entry in _customQuantities.entries)
                if (entry.value > 0) entry.key: entry.value,
            },
            fabric: _customFabric,
            referenceId: referenceId,
            grandTotal: grandTotal,
            amountDueNow: amountDueNow,
            successUrl: AppLinks.paymentCallbackUrl(
              success: true,
              flow: 'custom',
              referenceId: referenceId,
            ),
            cancelUrl: AppLinks.paymentCallbackUrl(
              success: false,
              flow: 'custom',
              referenceId: referenceId,
            ),
            orderType: _deliveryOption == _DeliveryOption.delivery ? 'Delivery' : 'Pickup',
            address: _deliveryOption == _DeliveryOption.delivery
                ? '${_streetController.text.trim()}, $_selectedBarangay, $_selectedMunicipality, Bulacan $_zipCode'
                : 'Pick up at Bulacan Hub (3620 MacArthur Hwy, Marilao, Bulacan)',
            billingName: (profile?.fullName ?? user.userMetadata?['full_name']?.toString() ?? 'Guest User').trim(),
            billingEmail: (profile?.email ?? user.email ?? '').trim(),
            billingPhone: _normalizePhone(profile?.contactNumber?.toString()),
            city: checkoutCity,
            postalCode: checkoutZipCode,
            streetAddress: checkoutStreet,
            zoneId: selectedZone?.id,
            instructions: _customInstructionsController.text.trim(),
          );

      if ((result.sessionId ?? '').trim().isNotEmpty) {
        await PaymentSessionStore.save(
          PendingPaymentSession(
            sessionId: result.sessionId!,
            flow: 'custom',
            referenceId: referenceId,
          ),
        );
      }

      if (!mounted) return;
      setState(() => _waitingForPaymentReturn = true);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MobileWebViewScreen(
            title: 'Secure Checkout',
            initialUrl: result.checkoutUrl,
            mode: MobileWebViewMode.payment,
          ),
        ),
      );
    } catch (error) {
      await PaymentSessionStore.clear();
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _waitingForPaymentReturn = false;
        });
      }
    }
  }

  String? _normalizePhone(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('0') && raw.length == 11) {
      return '+63${raw.substring(1)}';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final items = _resolveItems();
    final customDesign = _customDesign();
    final customUnitPrice = customDesign?.unitPrice ?? 350.0;
    final itemsTotal = _isCustomDesignFlow
        ? _customTotalPieces * customUnitPrice
        : items.fold<double>(0, (sum, item) => sum + item.subtotal);
    final deliveryFee = _deliveryFeeFor(_selectedMunicipality);
    final grandTotal = itemsTotal + deliveryFee;
    final amountDueNow = _isCustomDesignFlow
        ? grandTotal * 0.5
        : _paymentType == _PaymentType.full
            ? grandTotal
            : grandTotal * 0.5;
    final remainingBalance = grandTotal - amountDueNow;
    final municipality = _municipalityByName(_selectedMunicipality);
    final municipalityValue = municipality?.name;
    final barangayValue =
        municipality?.barangays.contains(_selectedBarangay) == true ? _selectedBarangay : null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Checkout',
          style: AppTextStyles.heading.copyWith(fontSize: 22),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : !_isCustomDesignFlow && items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No items selected for checkout.',
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.gold, width: 1.3),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1AF59E0B),
                              blurRadius: 22,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Amount due now',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.muted,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'PHP ${amountDueNow.toStringAsFixed(0)}',
                              style: AppTextStyles.largeTitle.copyWith(
                                color: AppColors.text,
                                fontSize: 40,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isCustomDesignFlow || _paymentType == _PaymentType.deposit
                                  ? '50% downpayment for your order'
                                  : 'Full payment for your order',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_isCustomDesignFlow && customDesign != null) ...[
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Custom design', style: AppTextStyles.heading),
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 84,
                                    height: 84,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: (customDesign.previewImage ?? '').isNotEmpty
                                        ? Image.network(
                                            customDesign.previewImage!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => const Icon(Icons.style_rounded),
                                          )
                                        : const Icon(Icons.style_rounded, size: 32),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          customDesign.name,
                                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Garment: ${customDesign.garmentType}',
                                          style: AppTextStyles.caption,
                                        ),
                                        if ((customDesign.sizeLabel ?? '').isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              'Suggested size: ${customDesign.sizeLabel}',
                                              style: AppTextStyles.caption,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (_hasPrefilledBulkConfiguration) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7E6),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: const Color(0xFFF5D28C)),
                                  ),
                                  child: Text(
                                    'Bulk order details were already configured in the customizer. Review them below, then continue to payment.',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.goldDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _StaticInfo(
                                  label: 'Fabric / Material',
                                  value: _customFabric,
                                ),
                                const SizedBox(height: 12),
                                _BulkQuantitiesCard(quantities: _customQuantities),
                                if (customDesign.roster.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _BulkRosterCard(roster: customDesign.roster),
                                ],
                                if (_customInstructionsController.text.trim().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _StaticMultilineInfo(
                                    label: 'Design / Production Notes',
                                    value: _customInstructionsController.text.trim(),
                                  ),
                                ],
                              ] else ...[
                                _FieldLabel('Fabric / Material'),
                                DropdownButtonFormField<String>(
                                  initialValue: _customFabric,
                                  items: [
                                    for (final fabric in _customFabricOptions)
                                      DropdownMenuItem<String>(
                                        value: fabric,
                                        child: Text(fabric),
                                      ),
                                  ],
                                  decoration: _inputDecoration('Choose material'),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _customFabric = value);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _FieldLabel('Size quantities'),
                                for (final size in _customQuantities.keys) ...[
                                  _CustomSizeRow(
                                    size: size,
                                    quantity: _customQuantities[size] ?? 0,
                                    onDecrease: () => _changeCustomQuantity(size, -1),
                                    onIncrease: () => _changeCustomQuantity(size, 1),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                const SizedBox(height: 4),
                                _FieldLabel('Design / Production Notes'),
                                TextField(
                                  controller: _customInstructionsController,
                                  maxLines: 3,
                                  decoration: _inputDecoration(
                                    'Optional notes for print placement, roster, or production details',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Delivery logistics', style: AppTextStyles.heading),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _ChoiceTile(
                                    label: 'Delivery',
                                    subtitle: 'Ship within Bulacan',
                                    active: _deliveryOption == _DeliveryOption.delivery,
                                    onTap: () => setState(() => _deliveryOption = _DeliveryOption.delivery),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ChoiceTile(
                                    label: 'Pick up',
                                    subtitle: 'Marilao hub',
                                    active: _deliveryOption == _DeliveryOption.pickup,
                                    onTap: () => setState(() => _deliveryOption = _DeliveryOption.pickup),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (_deliveryOption == _DeliveryOption.delivery) ...[
                              _FieldLabel('Street / House Number / Landmark'),
                              TextField(
                                controller: _streetController,
                                decoration: _inputDecoration('Enter your street address'),
                              ),
                              const SizedBox(height: 12),
                              _FieldLabel('Municipality'),
                              DropdownButtonFormField<String>(
                                initialValue: municipalityValue,
                                items: [
                                  for (final item in bulacanMunicipalities)
                                    DropdownMenuItem(
                                      value: item.name,
                                      child: Text(item.name),
                                    ),
                                ],
                                decoration: _inputDecoration('Select location'),
                                onChanged: (value) {
                                  final selected = _municipalityByName(value ?? '');
                                  setState(() {
                                    _selectedMunicipality = value ?? '';
                                    _selectedBarangay = '';
                                    _zipCode = selected?.zipCode ?? '';
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _FieldLabel('Barangay'),
                              DropdownButtonFormField<String>(
                                initialValue: barangayValue,
                                items: [
                                  for (final barangay in municipality?.barangays ?? const <String>[])
                                    DropdownMenuItem(
                                      value: barangay,
                                      child: Text(barangay),
                                    ),
                                ],
                                decoration: _inputDecoration(
                                  municipality == null ? 'Select municipality first' : 'Select barangay',
                                ),
                                onChanged: municipality == null
                                    ? null
                                    : (value) => setState(() => _selectedBarangay = value ?? ''),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StaticInfo(
                                      label: 'Province',
                                      value: municipality?.name.isNotEmpty == true ? 'Bulacan' : 'Bulacan',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _StaticInfo(
                                      label: 'ZIP Code',
                                      value: _zipCode.isEmpty ? 'Auto-filled' : _zipCode,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7E6),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFF5D28C)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bulacan Premium Hub',
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '3620 MacArthur Hwy, Marilao, Bulacan',
                                      style: AppTextStyles.caption,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Estimated ready date: ${_estimateDate ?? 'Calculating...'}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.goldDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment strategy', style: AppTextStyles.heading),
                            const SizedBox(height: 12),
                            if (_isCustomDesignFlow)
                              _ChoiceTile(
                                label: '50% Deposit',
                                subtitle: 'Custom orders currently start with a 50% deposit',
                                active: true,
                                onTap: () {},
                              )
                            else ...[
                              _ChoiceTile(
                                label: '50% Deposit',
                                subtitle: 'Pay half now, settle the rest later',
                                active: _paymentType == _PaymentType.deposit,
                                onTap: () => setState(() => _paymentType = _PaymentType.deposit),
                              ),
                              const SizedBox(height: 10),
                              _ChoiceTile(
                                label: 'Full Payment',
                                subtitle: 'Pay the entire order now',
                                active: _paymentType == _PaymentType.full,
                                onTap: () => setState(() => _paymentType = _PaymentType.full),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order summary', style: AppTextStyles.heading),
                            const SizedBox(height: 14),
                            if (_isCustomDesignFlow && customDesign != null) ...[
                              _CustomDesignSummaryTile(
                                design: customDesign,
                                totalPieces: _customTotalPieces,
                                fabric: _customFabric,
                              ),
                              const SizedBox(height: 10),
                            ] else
                              for (final item in items) ...[
                                _CheckoutItemTile(item: item),
                                const SizedBox(height: 10),
                              ],
                            const Divider(),
                            _SummaryRow(label: 'Subtotal', value: 'PHP ${itemsTotal.toStringAsFixed(0)}'),
                            _SummaryRow(label: 'Delivery fee', value: 'PHP ${deliveryFee.toStringAsFixed(0)}'),
                            _SummaryRow(label: 'Order total', value: 'PHP ${grandTotal.toStringAsFixed(0)}', strong: true),
                            const SizedBox(height: 6),
                            _SummaryRow(
                              label: _isCustomDesignFlow || _paymentType == _PaymentType.deposit
                                  ? 'Due now'
                                  : 'Pay now',
                              value: 'PHP ${amountDueNow.toStringAsFixed(0)}',
                              strong: true,
                              accent: true,
                            ),
                            if (_isCustomDesignFlow || _paymentType == _PaymentType.deposit)
                              _SummaryRow(
                                label: 'Remaining balance',
                                value: 'PHP ${remainingBalance.toStringAsFixed(0)}',
                              ),
                            if (_estimateDate != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Estimated completion: $_estimateDate',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.goldDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: AppTextStyles.caption.copyWith(color: Colors.red.shade700),
                        ),
                      ],
                      const SizedBox(height: 16),
                      PrimaryButton(
                        text: _submitting
                            ? 'Preparing checkout...'
                            : _waitingForPaymentReturn
                                ? 'Waiting for payment confirmation...'
                                : 'Proceed to Pay',
                        isLoading: _submitting || _waitingForPaymentReturn,
                        onPressed: _submitting || _waitingForPaymentReturn
                            ? null
                            : () => _submitCheckout(items),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Payment now stays inside the app and returns here automatically.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption,
                      ),
                      if (_isCustomDesignFlow)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Custom design checkout uses the backend custom-order flow and returns here automatically after PayMongo.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption,
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.gold),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _StaticInfo extends StatelessWidget {
  const _StaticInfo({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StaticMultilineInfo extends StatelessWidget {
  const _StaticMultilineInfo({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _BulkQuantitiesCard extends StatelessWidget {
  const _BulkQuantitiesCard({
    required this.quantities,
  });

  final Map<String, int> quantities;

  @override
  Widget build(BuildContext context) {
    final activeEntries = quantities.entries.where((entry) => entry.value > 0).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Size quantities', style: AppTextStyles.caption),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in activeEntries)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFF5D28C)),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldDark,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BulkRosterCard extends StatelessWidget {
  const _BulkRosterCard({
    required this.roster,
  });

  final List<Map<String, dynamic>> roster;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Roster', style: AppTextStyles.caption),
          const SizedBox(height: 10),
          for (var index = 0; index < roster.length; index++) ...[
            if (index > 0) const Divider(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.text,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roster[index]['name']?.toString().trim().isNotEmpty == true
                            ? roster[index]['name'].toString()
                            : 'Unnamed',
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Size ${roster[index]['size'] ?? '-'}'
                        '${(roster[index]['number']?.toString().trim().isNotEmpty == true) ? ' • No. ${roster[index]['number']}' : ''}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? AppColors.gold : const Color(0xFFE5E7EB),
            width: active ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              active ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: active ? AppColors.goldDark : AppColors.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutItemTile extends StatelessWidget {
  const _CheckoutItemTile({required this.item});

  final CheckoutLineItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: (item.image ?? '').isNotEmpty
              ? Image.network(
                  item.image!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.checkroom_rounded),
                )
              : const Icon(Icons.checkroom_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  'Qty ${item.quantity}',
                  if ((item.size ?? '').isNotEmpty) 'Size ${item.size}',
                  if ((item.fabric ?? '').isNotEmpty) item.fabric!,
                  if ((item.customName ?? '').isNotEmpty)
                    'Name ${item.customName}',
                  if ((item.customNumber ?? '').isNotEmpty)
                    'No. ${item.customNumber}',
                ].join(' - '),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        Text(
          'PHP ${item.subtotal.toStringAsFixed(0)}',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _CustomSizeRow extends StatelessWidget {
  const _CustomSizeRow({
    required this.size,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String size;
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              size,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          Text(
            '$quantity',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
          ),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _CustomDesignSummaryTile extends StatelessWidget {
  const _CustomDesignSummaryTile({
    required this.design,
    required this.totalPieces,
    required this.fabric,
  });

  final CustomDesignDraft design;
  final int totalPieces;
  final String fabric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: (design.previewImage ?? '').isNotEmpty
              ? Image.network(
                  design.previewImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.style_rounded),
                )
              : const Icon(Icons.style_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                design.name,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalPieces pcs • $fabric',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        Text(
          'PHP ${(totalPieces * (design.unitPrice ?? 350)).toStringAsFixed(0)}',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool strong;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ? AppColors.goldDark : AppColors.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: strong ? AppColors.text : AppColors.muted,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
