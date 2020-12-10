import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:common_utils/common_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/net/DioManager.dart';
import 'package:flutter_app/utils/router.dart';
import 'package:flutter_app/utils/util_mine.dart';
import 'package:flutter_app/widget/loading.dart';
import 'package:flutter_app/widget/search_widget.dart';
import 'package:flutter_app/widget/sliver_footer.dart';

class SearchGoods extends StatefulWidget {
  final Map arguments;

  SearchGoods({this.arguments});

  @override
  _SearchGoodsState createState() => _SearchGoodsState();
}

class _SearchGoodsState extends State<SearchGoods> {
  TextEditingController controller = TextEditingController();
  ScrollController _scrollController = new ScrollController();
  bool isLoading = false;
  String textValue = '';
  var searchTipsData = [];
  var searchTipsresultData = [];

  var serachResult = false;

  //初始化,状态
  var isFirstLoading = true;
  var hasMore = false;
  var bottomTipsText = '搜索更大的世界';

  //请求是以这个参数为加载更多
  var paeSize = 40;
  var itemId = 0;
  var keyword = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      textValue = widget.arguments['id'];
    });

    _getSearchTips();
    _scrollController.addListener(() {
      // 如果下拉的当前位置到scroll的最下面
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (hasMore) {
          isLoading = true;
          _getTipsResult();
        }
      }
    });
  }

//  http://m.you.163.com/xhr/search/search.json?keyword=%E9%9B%B6%E9%A3%9F&sortType=0&descSorted=false&categoryId=0&matchType=0&floorPrice=-1&upperPrice=-1&size=40&itemId=0&stillSearch=false&searchWordSource=1&needPopWindow=true&_stat_search=userhand
//  http://m.you.163.com/xhr/search/search.json?keyword=%E9%9B%B6%E9%A3%9F&sortType=0&descSorted=false&categoryId=0&matchType=1&floorPrice=-1&upperPrice=-1&size=40&itemId=3827056&stillSearch=false&searchWordSource=1&needPopWindow=false
  void _getTipsResult() {
    var params = {
      'keyword': keyword,
      'sortType': '0',
      'descSorted': 'false',
      'categoryId': '0',
      'matchType': '0',
      'floorPrice': '-1',
      'upperPrice': '-1',
      'size': paeSize,
      'itemId': itemId,
      'stillSearch': 'false',
      'searchWordSource': '7',
      'needPopWindow': 'false'
    };
    if (!hasMore) {
      params.addAll({'_stat_search': 'userhand'});
    } else {
      params.remove('_stat_search');
    }
    DioManager.get('xhr/search/search.json', params, (data) {
      setState(() {
        isLoading = false;
        var newDirectlyList = [];
        var directlyList = data['data']['directlyList'];
        if (directlyList != null) {
          newDirectlyList.addAll(directlyList);
        }
        if (newDirectlyList.isNotEmpty) {
          searchTipsresultData.addAll(data['data']['directlyList']);
          itemId = searchTipsresultData[searchTipsresultData.length - 1]
              ['itemTagList'][0]['itemId'];
          hasMore = data['data']['hasMore'];
          if (!hasMore) {
            bottomTipsText = '没有更多了';
          }
          serachResult = true;
        } else {
          hasMore = false;
          isFirstLoading = true;
          bottomTipsText = '没有找到您想要的内容';
        }
      });
    });
  }

  void _getSearchTips() async {
    setState(() {
      isLoading = true;
    });
    var params = {'keywordPrefix': textValue};
    DioManager.post(
      'xhr/search/searchAutoComplete.json',
      params,
      (data) {
        setState(() {
          isLoading = false;
          searchTipsData = data['data'];
          serachResult = false;
          hasMore = false;
          if (searchTipsData.length == 0) {
            bottomTipsText = '暂时没有您想要的内容';
          } else {
            bottomTipsText = '搜索更大的世界';
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: <Widget>[
//          _showPop(),
          isLoading ? Loading() : _showPop(),
          Container(
            decoration: BoxDecoration(color: Colors.white),
            child: SearchWidget(
              textValue: textValue,
              hintText: '输入搜索',
              controller: controller,
              onValueChangedCallBack: (value) {
                textValue = value;
                _getSearchTips();
              },
              onSearchBtnClick: (value) {
                Util.hideKeyBord(context);
                textValue = value;
                _getSearchTips();
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _showPop() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
          SliverList(
            delegate:
                SliverChildBuilderDelegate((BuildContext context, int index) {
              return Container(
                height: MediaQuery.of(context).padding.top + 50,
              );
            }, childCount: 1),
          ),
          serachResult ? buildNullSliver() : buildSearchTips(),
          !serachResult ? buildNullSliver() : buildSearchResult(),
          SliverFooter(hasMore: hasMore, tipsText: bottomTipsText),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    controller.dispose();
    _scrollController.dispose();
  }

//  http://m.you.163.com/xhr/search/search.json?keyword=%E4%BC%91%E9%97%B2%E9%9B%B6%E9%A3%9F&sortType=0&descSorted=false&categoryId=0&matchType=0&floorPrice=-1&upperPrice=-1&size=40&itemId=0&stillSearch=false&searchWordSource=7&needPopWindow=true&_stat_search=auto
//  http://m.you.163.com/xhr/search/search.json?keyword=%E4%BC%91%E9%97%B2%E9%9B%B6%E9%A3%9F&sortType=0&descSorted=false&categoryId=0&matchType=0&floorPrice=-1&upperPrice=-1&size=40&itemId=1056006&stillSearch=false&searchWordSource=7&needPopWindow=false
  buildImage(int index) {
    return Container(
      child: Stack(
        alignment: const FractionalOffset(0.0, 1), //方法一
        children: <Widget>[
          Container(
            height: 30,
            child: CachedNetworkImage(
              imageUrl: searchTipsresultData[index]['listPromBanner']
                  ['bannerContentUrl'],
              fit: BoxFit.fill,
            ),
          ),
          Container(
            width: 70,
            height: 35,
            child: CachedNetworkImage(
              imageUrl: searchTipsresultData[index]['listPromBanner']
                  ['bannerTitleUrl'],
              fit: BoxFit.fill,
            ),
          ),
          Container(
              width: 70,
              height: 35,
              child: Center(
                child: Stack(
                  alignment: const FractionalOffset(0.5, 0.5),
                  children: <Widget>[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          searchTipsresultData[index]['listPromBanner']
                              ['promoTitle'],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                        Text(
                          searchTipsresultData[index]['listPromBanner']
                              ['promoSubTitle'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
          Positioned(
            left: 75,
            height: 30,
            child: Container(
                margin: EdgeInsets.only(top: 5),
                child: Center(
                  child: Text(
                      searchTipsresultData[index]['listPromBanner']['content'],
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                )),
          ),
        ],
      ),
    );
  }

  buildBottomText(int index) {
    return Container(
      decoration: BoxDecoration(color: Color(0xFFF1ECE2)),
      padding: EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.centerLeft,
      child: Text(
        searchTipsresultData[index]['simpleDesc'],
        style: TextStyle(color: Color(0XFF875D2A), fontSize: 14),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  SliverList buildNullSliver() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        return Container();
      }, childCount: 1),
    );
  }

  SliverGrid buildSearchTips() {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        Widget widget = Container(
            margin: EdgeInsets.only(left: 15),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 0.5, color: Colors.grey[200]),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    searchTipsData[index],
                    textAlign: TextAlign.start,
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(right: 10),
                  child: Image.asset(
                    'assets/images/search_icon.png',
                    width: 12.0,
                    height: 12.0,
                  ),
                )
              ],
            ));
        return GestureDetector(
          child: widget,
          onTap: () {
            setState(() {
              searchTipsresultData = [];
              Util.hideKeyBord(context);
              keyword = searchTipsData[index];
              isLoading = true;
              _getTipsResult();
            });
          },
        );
      }, childCount: searchTipsData.length),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 8,
          mainAxisSpacing: 0,
          crossAxisSpacing: 0),
    );
  }

  SliverGrid buildSearchResult() {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        Widget widget = Container(
          padding: EdgeInsets.only(bottom: 5),
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.transparent),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 7,
                child: Container(
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: searchTipsresultData[index]['primaryPicUrl'],
                    fit: BoxFit.fill,
                  ),
                  decoration: BoxDecoration(color: Colors.grey[200]),
                ),
              ),
              searchTipsresultData[index]['listPromBanner'] != null
                  ? buildImage(index)
                  : Expanded(
                      flex: 1,
                      child: Container(
                        width: double.infinity,
                        child: buildBottomText(index),
                      )),
              Container(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  searchTipsresultData[index]['name'],
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                child: Text(
                  '￥${searchTipsresultData[index]['retailPrice']}',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                      fontWeight: FontWeight.bold),
                ),
              ),
              searchTipsresultData[index]['itemTagList'] == null
                  ? Container()
                  : Container(
                      margin: EdgeInsets.symmetric(vertical: 5),
                      padding: EdgeInsets.fromLTRB(2, 1, 2, 1),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          border: Border.all(color: Colors.red, width: 0.5)),
                      child: Text(
                        '${searchTipsresultData[index]['itemTagList'][0]['name'] == null ? '年货特惠' : searchTipsresultData[index]['itemTagList'][0]['name']}',
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
            ],
          ),
        );
        return GestureDetector(
          child: widget,
          onTap: () {
            Routers.push(Util.goodDetailTag, context,
                {'id': searchTipsresultData[index]['id']});
          },
        );
      }, childCount: searchTipsresultData.length),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10),
    );
  }

  //获取详情
  void _getDetail() async {
//    https://m.you.163.com/xhr/item/detail.json
    Response response = await Dio().post(
        'https://m.you.163.com/xhr/item/detail.json',
        queryParameters: {'id': '1023000'});
    String dataStr = json.encode(response.data);
    Map<String, dynamic> dataMap = json.decode(dataStr);
    var dataMap2 = dataMap['data'];
    LogUtil.e(json.encode(dataMap), tag: "////");
  }
}
