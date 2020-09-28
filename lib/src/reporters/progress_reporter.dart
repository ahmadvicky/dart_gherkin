import './stdout_reporter.dart';
import '../gherkin/runnables/debug_information.dart';
import '../gherkin/steps/step_run_result.dart';
import './message_level.dart';
import './messages.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart';
import 'dart:io';

class ProgressReporter extends StdoutReporter {

  List<String> scenarioList = [];

  @override
  Future<void> onScenarioStarted(StartedMessage message) async {
    printMessageLine(
        'Running scenario: ${_getNameAndContext(message.name, message.context)}',
        StdoutReporter.WARN_COLOR);
    scenarioList.add('Running scenario ${message.name}');
  }

  @override
  Future<void> onScenarioFinished(ScenarioFinishedMessage message) async {
    printMessageLine("${message.passed ? 'PASSED' : 'FAILED'}: Scenario ${message.name}",
        message.passed ? StdoutReporter.PASS_COLOR : StdoutReporter.FAIL_COLOR);
    scenarioList.add('Finish Scenario ${message.name}');

    final pdf = pw.Document();

    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        build: (pw.Context context) {
          return pw.Column(
              children: [
                pw.Container(
                    margin: pw.EdgeInsets.only(bottom: 10),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                        '${message.name}',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        )
                    )
                ),
                pw.ListView.builder(itemCount: scenarioList.length, itemBuilder: (context,index) {
                  return pw.Container(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Text(
                          '${scenarioList[index]}',
                          textAlign: pw.TextAlign.left,
                          style: TextStyle(
                            fontSize: 12,
                          )
                      )
                  );

                })
              ]
          ); // Center
        }));
    // scenarioList.forEach((element) {
    //
    //   // Page
    // });

    final file = File("report/${_getNameFile(message.name)}.pdf");
    await file.writeAsBytes(pdf.save());

  }



  @override
  Future<void> onStepFinished(StepFinishedMessage message) async {
    scenarioList.add('${message.name}');
    printMessageLine(
        [
          '  ',
          _getStatePrefixIcon(message.result.result),
          _getNameAndContext(message.name, message.context),
          // _getExecutionDuration(message.result),
          _getReasonMessage(message.result),
          _getErrorMessage(message.result)
        ].join((' ')).trimRight(),
        _getMessageColour(message.result.result));

    if (message.attachments.isNotEmpty) {
      message.attachments.forEach((attachment) {
        var attachment2 = attachment;
        printMessageLine(
            [
              '    ',
              'Attachment',
              "(${attachment2.mimeType})${attachment.mimeType == 'text/plain' ? ': ${attachment.data}' : ''}"
            ].join((' ')).trimRight(),
            StdoutReporter.RESET_COLOR);
      });
    }
  }

  @override
  Future<void> message(String message, MessageLevel level) async {
    // ignore messages
  }

  String _getReasonMessage(StepResult stepResult) {
    if (stepResult.resultReason != null && stepResult.resultReason.isNotEmpty) {
      return '\n      ${stepResult.resultReason}';
    } else {
      return '';
    }
  }

  String _getErrorMessage(StepResult stepResult) {
    if (stepResult is ErroredStepResult) {
      return '\n${stepResult.exception}\n${stepResult.stackTrace}';
    } else {
      return '';
    }
  }

  String _getNameAndContext(String name, RunnableDebugInformation context) {
    return "$name";
    // "${context.filePath.replaceAll(RegExp(r"\.\\"), "")}:${context.lineNumber}";
  }

  String _getNameFile(String name){
    name = name.replaceAll(' ','');
    return name;
  }

  String _getExecutionDuration(StepResult stepResult) {
    return 'took ${stepResult.elapsedMilliseconds}ms';
  }

  String _getStatePrefixIcon(StepExecutionResult result) {
    switch (result) {
      case StepExecutionResult.pass:
        return '√';
      case StepExecutionResult.error:
      case StepExecutionResult.fail:
      case StepExecutionResult.timeout:
        return '×';
      case StepExecutionResult.skipped:
        return '-';
    }

    return '';
  }

  String _getMessageColour(StepExecutionResult result) {
    switch (result) {
      case StepExecutionResult.pass:
        return StdoutReporter.PASS_COLOR;
      case StepExecutionResult.fail:
        return StdoutReporter.FAIL_COLOR;
      case StepExecutionResult.error:
        return StdoutReporter.FAIL_COLOR;
      case StepExecutionResult.skipped:
        return StdoutReporter.WARN_COLOR;
      case StepExecutionResult.timeout:
        return StdoutReporter.FAIL_COLOR;
    }

    return StdoutReporter.RESET_COLOR;
  }
}
