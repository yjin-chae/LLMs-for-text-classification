def openai_prediction(model, test, n_chunks, result_file_name):
    preds = pd.DataFrame()
    responses = []

    for batch in np.array_split(test, n_chunks): ## divide the data by n_chunks so that each batch has <= 20 entries.
        batch['original_index'] = batch.index
        batch = batch.reset_index(drop=True)
        
        response = openai.Completion.create(
            model=model,
            prompt=list(batch['prompt']),
            stop=["\n"],
            temperature=0)
        
        for res in response.choices:
            batch.loc[res.index, "preds"] = str.strip(res['text'])
        
        preds = pd.concat([preds, batch], axis=0)
        responses.append(response)
        
        time.sleep(1.0) ## Due to Rate limit
    
    if not os.path.exists("../predicted_labels"):
        os.mkdir("../predicted_labels")
    
    with open("../predicted_labels/" + result_file_name + '.json', 'w', encoding='utf-8') as f:
        json.dump(responses, f)
    test_preds = pd.concat([test, preds], axis=1)
    test_preds.to_csv("../predicted_labels/" + result_file_name + ".csv", index=False)
    
    return test_preds, responses