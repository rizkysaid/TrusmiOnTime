class OptionsModel {
  String? option;
  String? status;

  OptionsModel({this.option, this.status});

  OptionsModel.fromJson(Map<String, dynamic> json) {
    option = json['option'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['option'] = this.option;
    data['status'] = this.status;
    return data;
  }
}
