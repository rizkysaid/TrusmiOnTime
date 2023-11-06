import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:login_absen/core/bloc/profile/profile_bloc.dart';
import 'package:login_absen/core/config/endpoint.dart';
import 'package:login_absen/core/controller/ProfileController.dart';

class SingleBestEmployee extends StatelessWidget {
  SingleBestEmployee({super.key, this.response, required this.userID, required this.date, this.profileBloc, this.apiToken});
  final dynamic response;
  final String userID;
  final String date;
  final dynamic profileBloc;
  final dynamic apiToken;

  final ProfileBloc _profileBloc = ProfileBloc();

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
                height: MediaQuery.of(context).size.height * 0.3,
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 15),
                      width: double.infinity,
                      child: Center(
                        child: DefaultTextStyle(
                          child: Text('Best Employee Of The Month'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 15, bottom: 10),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Column(
                                  children: [
                                    DefaultTextStyle(
                                      child: Text("Periode"),
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Container(
                                      child: Column(
                                        children: [
                                          DefaultTextStyle(
                                            child:
                                            Text(DateFormat('MMMM').format(
                                              DateTime(
                                                0,
                                                int.parse(
                                                  response['periode']
                                                      .substring(5, 7),
                                                ),
                                              ),
                                            )),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          DefaultTextStyle(
                                            child: Text(response['periode']
                                                .substring(0, 4)),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.fromLTRB(
                              20,
                              5,
                              20,
                              0,
                            ),
                            padding: EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage: NetworkImage(
                                Endpoint.baseIp +
                                    '/' +
                                    response['data']['best'][0]
                                    ['profile_picture'],
                              ),
                              radius: 45.0,
                              // child: CachedNetworkImage(
                              //     imageUrl:
                              //         '${Endpoint.baseIp}/${response['data']['best'][0]['profile_picture']}'),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Center(
                                child: Column(
                                  children: [],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DefaultTextStyle(
                      child: Text(response['data']['best'][0]['employee']),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DefaultTextStyle(
                      child: Text(response['data']['best'][0]['jabatan']),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
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
                    _profileBloc.add(InitialProfile());
                    // getProfil(userID, date);
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
            Positioned(
              top: 70,
              right: 15,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    children: [
                      DefaultTextStyle(
                        child: Text("KPI"),
                        style: TextStyle(color: Colors.white),
                      ),
                      Image(
                        image: AssetImage('assets/gold-medal.png'),
                        width: 80,
                        height: 80,
                      ),
                    ],
                  ),
                  Positioned(
                    top: 32,
                    // left: 25,
                    child: Center(
                      child: DefaultTextStyle(
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        child: Text(
                          response['data']['best'][0]['score'],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(
          height: 20,
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 5),
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
                    // elevation: 5,
                    // shape: RoundedRectangleBorder(
                    //   borderRadius: BorderRadius.circular(20),
                    // ),
                    child: ListTile(
                      // contentPadding: EdgeInsets.all(10),
                      // minVerticalPadding: 5,
                      leading: Container(
                        padding: EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(
                            Endpoint.baseIp +
                                '/' +
                                response['data']['bad'][index]
                                ['profile_picture'],
                          ),
                          radius: 30,
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
