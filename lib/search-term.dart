import 'package:flutter/material.dart';

class SearchTerm extends StatefulWidget {
  final String term;

  const SearchTerm({Key key, this.term}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _SearchTermState(term);
}

class _SearchTermState extends State<SearchTerm> {
  final String term;

  final _searchController = TextEditingController();

  _SearchTermState(this.term);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchController.text = term;
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
        child: Form(
            autovalidateMode: AutovalidateMode.always,
            child: Wrap(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'متن جستجو',
                    hintText: 'متن جستجو',
                  ),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ButtonBar(
                    alignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        child: const Text('تأیید'),
                        onPressed: () {
                          Navigator.of(context).pop(_searchController.text);
                        },
                      ),
                      TextButton(
                        child: const Text('انصراف'),
                        onPressed: () {
                          Navigator.of(context).pop(null);
                        },
                      )
                    ],
                  )),
            ])));
  }
}
