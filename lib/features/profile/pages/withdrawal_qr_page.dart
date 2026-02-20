import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/providers/wallet_providers.dart';
import '../../../core/theme/app_theme.dart';

/// Page pour générer un code QR et effectuer un retrait
class WithdrawalQRPage extends ConsumerStatefulWidget {
  const WithdrawalQRPage({super.key});

  @override
  ConsumerState<WithdrawalQRPage> createState() => _WithdrawalQRPageState();
}

class _WithdrawalQRPageState extends ConsumerState<WithdrawalQRPage> {
  final _amountController = TextEditingController();
  bool _isGeneratingQR = false;
  Map<String, dynamic>? _generatedQRData;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _generateQR() async {
    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant')),
      );
      return;
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant valide')),
      );
      return;
    }

    setState(() => _isGeneratingQR = true);

    try {
      final qrData = await ref.read(
        generateWithdrawalQRProvider(amount).future,
      );

      setState(() {
        _generatedQRData = qrData;
        _isGeneratingQR = false;
      });
    } catch (e) {
      setState(() => _isGeneratingQR = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retrait par Code QR'),
        backgroundColor: AppColors.primary,
      ),
      body: walletAsync.when(
        data: (wallet) {
          return _generatedQRData == null
              ? _buildInputForm(wallet)
              : _buildQRDisplay();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(error.toString()),
      ),
    );
  }

  /// Formulaire de saisie du montant
  Widget _buildInputForm(dynamic wallet) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'F CFA',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Solde disponible
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppDimensions.spacingL),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solde Disponible',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.success,
                  ),
                ),
                SizedBox(height: AppDimensions.spacingS),
                Text(
                  currencyFormat.format(wallet.availableBalance),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: AppDimensions.spacingL),

          // Info
          Container(
            padding: EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: AppColors.info, size: 20),
                SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    'Entrez le montant à retirer. Un code QR sera généré pour la transaction.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: AppDimensions.spacingL),

          // Montant
          Text('Montant à Retirer *', style: AppTextStyles.label),
          SizedBox(height: AppDimensions.spacingS),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            enabled: !_isGeneratingQR,
            decoration: InputDecoration(
              hintText: 'Ex: 50000',
              prefixText: 'F ',
              suffixText: 'CFA',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
          ),

          SizedBox(height: AppDimensions.spacingL),

          // Information sur les frais (optionnel)
          Container(
            padding: EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Frais de Transaction',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppDimensions.spacingS),
                Text(
                  '${_amountController.text.isEmpty ? "0" : ((double.tryParse(_amountController.text) ?? 0) * 0.02).toStringAsFixed(0)} F CFA (2%)',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),

          SizedBox(height: AppDimensions.spacingXl),

          // Bouton générer QR
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingQR ? null : _generateQR,
              icon: Icon(_isGeneratingQR ? null : Icons.qr_code_2),
              label: Text(
                _isGeneratingQR
                    ? 'Génération en cours...'
                    : 'Générer le Code QR',
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingL),
              ),
            ),
          ),

          SizedBox(height: AppDimensions.spacingM),

          // Bouton annuler
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ),
        ],
      ),
    );
  }

  /// Affichage du code QR généré
  Widget _buildQRDisplay() {
    final qrData = _generatedQRData!;
    final qrValue = qrData['qr_value'] as String?;
    final referenceId = qrData['reference_id'] as String?;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statut
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.success),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 24),
                SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code QR Généré avec Succès',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        'Scannez ce code au guichet de retrait',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: AppDimensions.spacingL),

          // Code QR
          if (qrValue != null)
            Center(
              child: Container(
                padding: EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: QrImageView(data: qrValue, size: 250.0),
              ),
            ),

          SizedBox(height: AppDimensions.spacingL),

          // Détails de la transaction
          if (referenceId != null)
            Container(
              padding: EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Montant', '${_amountController.text} F CFA'),
                  Divider(height: AppDimensions.spacingM),
                  _buildDetailRow('Référence', referenceId),
                  Divider(height: AppDimensions.spacingM),
                  _buildDetailRow('Statut', 'En Attente'),
                ],
              ),
            ),

          SizedBox(height: AppDimensions.spacingXl),

          // Instructions
          Container(
            padding: EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructions de Retrait',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppDimensions.spacingM),
                _buildInstructionStep(
                  '1',
                  'Allez au guichet de retrait',
                  'Présentez ce code QR à un agent',
                ),
                SizedBox(height: AppDimensions.spacingM),
                _buildInstructionStep(
                  '2',
                  'Scannez le code',
                  'L\'agent scannera votre code QR',
                ),
                SizedBox(height: AppDimensions.spacingM),
                _buildInstructionStep(
                  '3',
                  'Récupérez votre argent',
                  'Confirmez votre identité et recevez votre retrait',
                ),
              ],
            ),
          ),

          SizedBox(height: AppDimensions.spacingXl),

          // Bouton recommencer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _generatedQRData = null;
                  _amountController.clear();
                });
              },
              icon: const Icon(Icons.cached),
              label: const Text('Nouveau Retrait'),
            ),
          ),

          SizedBox(height: AppDimensions.spacingM),

          // Bouton fermer
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            ),
          ),
        ],
      ),
    );
  }

  /// Row pour afficher les détails
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Étape d'instruction
  Widget _buildInstructionStep(
    String number,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(description, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  /// Widget d'erreur
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            SizedBox(height: AppDimensions.spacingM),
            Text('Erreur', style: AppTextStyles.h3),
            SizedBox(height: AppDimensions.spacingS),
            Text(
              error,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
