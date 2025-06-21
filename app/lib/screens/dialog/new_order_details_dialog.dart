import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';

class NewOrderDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> pedidoData;
  final ApiService apiService;
  final int motoristaId;
  final Function onAccepted;

  const NewOrderDetailsDialog({
    Key? key,
    required this.pedidoData,
    required this.apiService,
    required this.motoristaId,
    required this.onAccepted,
  }) : super(key: key);

  @override
  State<NewOrderDetailsDialog> createState() => _NewOrderDetailsDialogState();
}

class _NewOrderDetailsDialogState extends State<NewOrderDetailsDialog> {
  bool _isAccepting = false;

  Future<void> _acceptOrder() async {
    setState(() {
      _isAccepting = true;
    });

    try {
      bool hasOngoing = await widget.apiService.hasOngoingOrder(widget.motoristaId);

      if (hasOngoing) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você já possui um pedido em andamento. Conclua-o antes de aceitar um novo.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final success = await widget.apiService.aceitarPedido(
        widget.pedidoData['pedidoId'],
        widget.motoristaId,
        position.latitude,
        position.longitude,
      );

      if (success && mounted) {
        Navigator.of(context).pop();
        widget.onAccepted();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao aceitar pedido')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final data = widget.pedidoData;

    return AlertDialog(
      title: const Text('Novo Pedido Disponível'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Tipo de Mercadoria:', data['tipoMercadoria']),
            _buildInfoRow('Origem:', data['origemEndereco']),
            _buildInfoRow('Destino:', data['destinoEndereco']),
            _buildInfoRow('Distância:', '${data['distanciaKm'].toStringAsFixed(1)} Km'),
            _buildInfoRow('Tempo estimado:', '${data['tempoEstimadoMinutos']} minutos'),
            _buildInfoRow('Distância até você:', '${data['distanciaMotorista'].toStringAsFixed(1)} Km'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Rejeitar'),
        ),
        ElevatedButton(
          onPressed: _isAccepting ? null : _acceptOrder,
          child: _isAccepting
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.0),
          )
              : const Text('Aceitar Pedido'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
