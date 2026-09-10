import 'package:flutter/material.dart';

class WorkerOnboardingScreen extends StatefulWidget {
  const WorkerOnboardingScreen({Key? key}) : super(key: key);

  @override
  _WorkerOnboardingScreenState createState() => _WorkerOnboardingScreenState();
}

class _WorkerOnboardingScreenState extends State<WorkerOnboardingScreen> {
  int _currentStep = 0;

  final _formKey = GlobalKey<FormState>();

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      // Submit and go to Worker Home
      Navigator.pushReplacementNamed(context, '/worker_home');
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Profile Setup'),
        centerTitle: true,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        steps: [
          Step(
            title: const Text('Personal'),
            content: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Full legal name'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Primary district/location'),
                ),
              ],
            ),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Professional'),
            content: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Primary trade'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Skills'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Years of experience'),
                ),
              ],
            ),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Cooperative'),
            content: Column(
              children: [
                DropdownButtonFormField<String>(
                  items: const [
                    DropdownMenuItem(value: 'coop1', child: Text('Andheri Electrical Cooperative')),
                    DropdownMenuItem(value: 'coop2', child: Text('Bandra Plumbing Cooperative')),
                  ],
                  onChanged: (value) {},
                  decoration: const InputDecoration(labelText: 'Select Cooperative'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your cooperative verifies your professional credentials and helps ensure fair work opportunities.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Documents'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Upload Verification Documents', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('Identity Proof'),
                  subtitle: const Text('Required for background check'),
                  trailing: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Upload'),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('Trade Certificate'),
                  subtitle: const Text('Required for skills verification'),
                  trailing: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Upload'),
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Review'),
            content: const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 64),
                    SizedBox(height: 16),
                    Text('Your worker profile is ready', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(
                      'Your cooperative will review your documents before you can accept jobs.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            isActive: _currentStep >= 4,
            state: _currentStep == 4 ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }
}
