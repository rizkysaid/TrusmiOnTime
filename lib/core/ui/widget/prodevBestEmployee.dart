import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:login_absen/core/bloc/profile/profile_bloc.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:login_absen/core/controller/ProfileController.dart';

class ProdevBestEmployee extends StatelessWidget {
  ProdevBestEmployee({super.key, this.response, required this.userID, required this.date, this.profileBloc, this.apiToken});
  final dynamic response;
  final String userID;
  final String date;
  final dynamic profileBloc;
  final dynamic apiToken;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                image: DecorationImage(
                  image: AssetImage('assets/background_new.png'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                ),
              ),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: Container()),
                    Container(
                      width: double.infinity,
                      child: Center(
                        child: Column(
                          children: [
                            DefaultTextStyle(
                              child: Text('Best Employee Of The Month'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            DefaultTextStyle(
                              child: Text(
                                DateFormat('MMMM').format(
                                  DateTime(
                                    0,
                                    int.parse(
                                      response['periode'].substring(5, 7),
                                    ),
                                  ),
                                ) +
                                    ' ' +
                                    response['periode'].substring(0, 4),
                              ),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child: Container()),
                    Container(
                      padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        childAspectRatio: 1.5,
                        children: List.generate(
                          response['data']['best'].length,
                              (index) {
                            return Card(
                              elevation: 0,
                              color: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width:
                                    MediaQuery.of(context).size.width / 2.5,
                                    padding: EdgeInsets.all(5),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.only(right: 30),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: EdgeInsets.all(2.5),
                                            child: CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                Endpoint.baseIp +
                                                    '/' +
                                                    response['data']['best']
                                                    [index]
                                                    ['profile_picture'],
                                              ),
                                              radius: 30,
                                            ),
                                          ),
                                        ),
                                        DefaultTextStyle(
                                          child: Text(
                                            response['data']['best'][index]
                                            ['employee'],
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Flexible(
                                          child: DefaultTextStyle(
                                            child: Text(
                                              response['data']['best'][index]
                                              ['jabatan'],
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 15,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          child: Image(
                                            image: AssetImage(
                                                'assets/gold-medal.png'),
                                            width: 70,
                                            height: 70,
                                          ),
                                        ),
                                        Positioned(
                                          top: 10,
                                          child: DefaultTextStyle(
                                            child: Text('KPI'),
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 8,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 18,
                                          child: DefaultTextStyle(
                                            child: Text(response['data']['best']
                                            [index]['score']),
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(child: Container()),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    profileBloc.add(InitialProfile());
                    ProfileController().getProfil(userID, date, profileBloc, apiToken);
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.lightBlue[50]!.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 17,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            children: [
              Container(
                // margin: EdgeInsets.only(bottom: 5),
                width: double.infinity,
                child: Center(
                  child: Column(
                    children: [
                      DefaultTextStyle(
                        child: Text('Bad Employee Of The Month'),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: response['data']['bad'].length,
                itemBuilder: (context, index) {
                  return Card(
                    // elevation: 3,
                    // shape: RoundedRectangleBorder(
                    //   borderRadius: BorderRadius.circular(20),
                    // ),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(
                            Endpoint.baseIp +
                                '/' +
                                response['data']['bad'][index]
                                ['profile_picture'],
                          ),
                          radius: 20,
                        ),
                      ),
                      title: Text(response['data']['bad'][index]['employee']),
                      subtitle: Text(response['data']['bad'][index]['jabatan']),
                      trailing: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: Chip(
                              label: Text(
                                response['data']['bad'][index]['score'],
                                style: TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                'KPI',
                                textAlign: TextAlign.center,
                                style:
                                TextStyle(fontSize: 9, color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
